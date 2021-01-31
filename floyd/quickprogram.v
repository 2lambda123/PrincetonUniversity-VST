Require Import VST.floyd.base.
Require Import VST.floyd.PTops.
Require Import VST.floyd.QPcomposite.

Fixpoint put_at_nth (i: nat) (c: ident * QP.composite) (rl: list (list (ident * QP.composite))) : list (list (ident * QP.composite)) :=
 match i, rl with
 | O, r::rl' =>  (c::r)::rl'
 | S j, r::rl' => r :: put_at_nth j c rl'
 | O, nil => (c::nil)::nil
 | S j, nil => nil :: put_at_nth j c nil
 end.

Fixpoint sort_rank (al: list (ident * QP.composite)) (rl: list (list (ident * QP.composite))) : list (ident * QP.composite) :=
  match al with
  | nil => List.fold_right (@app (ident * QP.composite)) nil rl
  | c::cl => sort_rank cl (put_at_nth (QP.co_rank (snd c)) c rl)
 end.

Definition compdef_of_compenv_element (x: ident * QP.composite) : composite_definition :=
  Composite (fst x) (QP.co_su (snd x)) (QP.co_members (snd x)) (QP.co_attr (snd x)).

Fixpoint filter_options {A B} (f: A -> option B) (al: list A) : list B :=
 match al with
 | nil => nil
 | a::al' => match f a with Some b => b :: filter_options f al' | None => filter_options f al' end
 end.

Definition is_builtin {F} (ix: ident * globdef (fundef F) type) : option (ident * QP.builtin) :=
 match ix with
 | (i, Gfun (External ef params ty cc)) =>
    match ef with
    | EF_builtin _ _ => Some (i, QP.mk_builtin ef params ty cc)
    | EF_runtime _ _ => Some (i, QP.mk_builtin ef params ty cc)
    | _ => None
    end
 | _ => None
 end.

Definition isNone {A} (x: option A) := match x with None => true | _ => false end.

Definition not_builtin {F} (ix: ident * globdef (fundef F) type) : bool := isNone (is_builtin ix).

Definition of_builtin {F} (ix: ident * QP.builtin) : ident * globdef (fundef F) type :=
 match ix with
 | (i, QP.mk_builtin ef params ty cc) => (i, Gfun (External ef params ty cc))
 end.

Definition program_of_QPprogram {F} (p: QP.program F) 
   : Errors.res (Ctypes.program F) :=
 let defs := map of_builtin p.(QP.prog_builtins) ++ PTree.elements p.(QP.prog_defs) in
 let public := p.(QP.prog_public) in
 let main := p.(QP.prog_main) in
 let types := map compdef_of_compenv_element 
                             (sort_rank (PTree.elements (p.(QP.prog_comp_env))) nil) in
 make_program types defs public main.

Definition QPprogram_of_program {F} (p: Ctypes.program F)
      (ha: PTree.t Z) (la: PTree.t legal_alignas_obs)   : QP.program F :=
 {| QP.prog_builtins :=  filter_options is_builtin p.(prog_defs);
   QP.prog_defs := PTree_Properties.of_list (filter not_builtin p.(prog_defs));
   QP.prog_public := p.(prog_public);
   QP.prog_main := p.(prog_main);
   QP.prog_comp_env := QPcomposite_env_of_composite_env 
                                        p.(prog_comp_env) ha la
 |}.

Import ListNotations.
(* Require VST.floyd.linking. *)

Definition signature_of_fundef (fd: Ctypes.fundef Clight.function):signature :=
match fd with
    Internal f => {| sig_args := map typ_of_type (map snd (Clight.fn_params f));
                     sig_res := rettype_of_type (Clight.fn_return f);
                     sig_cc := Clight.fn_callconv f |}
  | External ef tys rt cc => signature_of_type tys rt cc
 end.

Definition function_eq (f1 f2: Clight.function) : bool :=
eqb_type f1.(Clight.fn_return) f2.(Clight.fn_return) && 
eqb_calling_convention f1.(Clight.fn_callconv) f2.(Clight.fn_callconv) &&
eqb_list eqb_member f1.(Clight.fn_params) f2.(Clight.fn_params) && 
eqb_list eqb_member f1.(Clight.fn_vars) f2.(Clight.fn_vars) && 
eqb_list eqb_member f1.(Clight.fn_temps) f2.(Clight.fn_temps) && 
semax_lemmas.eq_dec_statement f1.(Clight.fn_body) f2.(Clight.fn_body).

Lemma eqb_calling_convention_refl: forall cc, eqb_calling_convention cc cc = true.
Proof.
destruct cc; simpl; auto.
unfold eqb_calling_convention; simpl.
rewrite ?eqb_reflx.
reflexivity.
Qed.

Lemma eqb_calling_convention_prop: forall cc1 cc2, eqb_calling_convention cc1 cc2 = true -> cc1=cc2.
Proof.
clear.
intros.
unfold eqb_calling_convention in H.
destruct cc1,cc2; simpl in *.
apply andb_prop in H. destruct H.
apply andb_prop in H0. destruct H0.
apply eqb_prop in H.
apply eqb_prop in H0.
apply eqb_prop in H1.
subst; auto.
Qed.

Lemma eqb_typelist_prop: forall t1 t2, eqb_typelist t1 t2 = true -> t1=t2.
Proof.
clear.
induction t1; destruct t2; simpl; intros; auto; try discriminate.
destruct (eqb_type t t0) eqn:?H; try discriminate.
apply eqb_type_true in H0.
f_equal; auto.
Qed.

Definition eqb_typ (t1 t2 : typ) : bool := 
 match t1, t2 with 
 | AST.Tint, AST.Tint => true
 | AST.Tfloat, AST.Tfloat => true
 | AST.Tlong, AST.Tlong => true
 | AST.Tsingle, AST.Tsingle => true
 | AST.Tany32, AST.Tany32 => true
 | AST.Tany64, AST.Tany64 => true
 | _, _ => false
 end.

Lemma eqb_typ_refl: forall c, eqb_typ c c = true.
Proof.
destruct c; simpl; try reflexivity.
Qed.

Lemma eqb_typ_prop: forall s1 s2, eqb_typ s1 s2 = true -> s1=s2.
Proof.
destruct s1, s2; simpl; intros; inv H; auto.
Qed.

Lemma eqb_typelist_refl: forall c, eqb_typelist c c = true.
Proof.
induction c; simpl; auto.
rewrite eqb_type_refl, IHc; auto.
Qed.

Definition eqb_rettype (t1 t2 : rettype) : bool := 
 match t1, t2 with 
 | AST.Tret a1, AST.Tret a2 => eqb_typ a1 a2
 | AST.Tint8signed, AST.Tint8signed => true
 | AST.Tint8unsigned, AST.Tint8unsigned => true
 | AST.Tint16signed, AST.Tint16signed => true
 | AST.Tint16unsigned, AST.Tint16unsigned => true
 | AST.Tvoid, AST.Tvoid => true
 | _, _ => false
 end.

Lemma eqb_rettype_refl: forall c, eqb_rettype c c = true.
Proof.
destruct c; simpl; try reflexivity.
apply eqb_typ_refl.
Qed.

Lemma eqb_rettype_prop: forall s1 s2, eqb_rettype s1 s2 = true -> s1=s2.
Proof.
destruct s1, s2; simpl; intros; inv H; auto.
f_equal.
apply eqb_typ_prop in H1; auto.
Qed.

Definition eqb_signature (s1 s2: signature) : bool :=
 match s1, s2 with
 |  mksignature args1 res1 cc1, mksignature args2 res2 cc2 =>
      eqb_list eqb_typ args1 args2 && eqb_rettype res1 res2 && eqb_calling_convention cc1 cc2
 end.

Lemma eqb_list_refl: forall {A} (f: A -> A -> bool),
  (forall a, f a a = true) ->
  forall al, eqb_list f al al = true.
Proof.
induction al; simpl; auto.
rewrite H, IHal; auto.
Qed.

Lemma eqb_list_prop:  forall {A} (f: A -> A -> bool),
  (forall a b, f a b = true -> a=b) ->
  forall al bl, eqb_list f al bl = true -> al = bl.
Proof.
induction al; destruct bl; simpl; intros; try discriminate; auto.
rewrite andb_true_iff in H0; destruct H0;
f_equal; auto.
Qed.

Lemma eqb_signature_refl: forall c, eqb_signature c c = true.
Proof.
destruct c; simpl; try reflexivity.
rewrite eqb_list_refl.
rewrite eqb_rettype_refl.
rewrite eqb_calling_convention_refl.
auto.
apply eqb_typ_refl.
Qed.

Lemma eqb_signature_prop: forall s1 s2, eqb_signature s1 s2 = true -> s1=s2.
Proof.
intros.
destruct s1, s2; simpl in *.
rewrite !andb_true_iff in H; destruct H as [[? ?] ?].
assert (sig_res = sig_res0). { 
 destruct sig_res, sig_res0; inv H0; auto.
 destruct t,t0; inv H3; auto.
}
assert (sig_args = sig_args0). {
 clear - H.
 revert sig_args0 H; induction sig_args; destruct sig_args0; simpl; intros; inv H; auto.
  rewrite andb_true_iff in H1; destruct H1; f_equal; auto.
  destruct a,t; inv H; auto.
}
apply eqb_calling_convention_prop in H1.
subst; auto.
Qed.

Definition eqb_memory_chunk (c1 c2: memory_chunk) : bool :=
 match c1, c2 with
 | Mint8signed, Mint8signed => true
 | Mint8unsigned, Mint8unsigned => true
 | Mint16signed, Mint16signed => true
 | Mint16unsigned, Mint16unsigned => true
 | Mint32, Mint32 => true
 | Mint64, Mint64 => true
 | Mfloat32, Mfloat32 => true
 | Mfloat64, Mfloat64 => true
 | Many32, Many32 => true
 | Many64, Many64 => true
 | _, _ => false
 end.

Lemma eqb_memory_chunk_refl: forall c, eqb_memory_chunk c c = true.
Proof.
destruct c; reflexivity.
Qed.

Lemma eqb_memory_chunk_prop: forall c1 c2, eqb_memory_chunk c1 c2 = true -> c1=c2.
Proof.
intros.
destruct c1,c2; inv H; reflexivity.
Qed.

Definition eqb_external_function (ef1 ef2: external_function) : bool :=
 match ef1, ef2 with
 | EF_external s1 sg1, EF_external s2 sg2 => String.eqb s1 s2 && eqb_signature sg1 sg2
 | EF_builtin s1 sg1, EF_builtin s2 sg2  => String.eqb s1 s2 && eqb_signature sg1 sg2
 | EF_runtime  s1 sg1, EF_runtime s2 sg2  => String.eqb s1 s2 && eqb_signature sg1 sg2
 | EF_vload ch1, EF_vload ch2 => eqb_memory_chunk ch1 ch2
 | EF_vstore ch1, EF_vstore ch2 => eqb_memory_chunk ch1 ch2
 | EF_malloc, EF_malloc => true
 | EF_free, EF_free => true
 | EF_memcpy i1 j1, EF_memcpy i2 j2 => Z.eqb i1 i2 && Z.eqb j1 j2
 | EF_annot p1 s1 t1, EF_annot p2 s2 t2 => Pos.eqb p1 p2 && String.eqb s1 s2 && eqb_list eqb_typ t1 t2
 | EF_annot_val p1 s1 t1, EF_annot_val p2 s2 t2 => Pos.eqb p1 p2 && String.eqb s1 s2 && eqb_typ t1 t2
 | EF_inline_asm s1 sg1 al1, EF_inline_asm s2 sg2 al2 =>
            String.eqb s1 s2 && eqb_signature sg1 sg2 && eqb_list String.eqb al1 al2
 | EF_debug p1 i1 t1, EF_debug p2 i2 t2 => 
            Pos.eqb p1 p2 && eqb_ident i1 i2 &&  eqb_list eqb_typ t1 t2
 | _ , _ => false
 end.

Lemma eqb_external_function_refl: forall c, eqb_external_function c c = true.
Proof.
destruct c; simpl; try reflexivity;
rewrite ?String.eqb_refl, ?eqb_signature_refl, ?eqb_memory_chunk_refl, ?Pos.eqb_refl, ?Z.eqb_refl,
  ?eqb_typ_refl, ?eqb_list_refl; auto.
apply eqb_typ_refl.
apply String.eqb_refl.
apply eqb_typ_refl.
Qed.

Lemma eqb_external_function_prop: forall c1 c2, eqb_external_function c1 c2 = true -> c1=c2.
Proof.
intros.
destruct c1,c2; inv H; try reflexivity;
rewrite ?andb_true_iff in *;
repeat match goal with H: _ /\ _ |- _ => destruct H end;
f_equal;
try (apply -> String.eqb_eq; auto);
try (apply eqb_signature_prop; auto);
try (apply eqb_memory_chunk_prop; auto);
try (apply -> Z.eqb_eq; auto);
try (apply -> Pos.eqb_eq; auto).
apply eqb_list_prop in H0; auto; apply eqb_typ_prop.
apply eqb_typ_prop; auto.
apply eqb_list_prop in H0; auto.
intros. apply String.eqb_eq; auto.
apply eqb_list_prop in H0; auto; apply eqb_typ_prop.
Qed.

Definition fundef_eq  (fd1 fd2: fundef Clight.function) : bool :=
match fd1, fd2 with
| Internal f1, Internal f2 => function_eq f1 f2
| External ef1 params1 res1 cc1, External ef2 params2 res2 cc2 => 
        eqb_external_function ef1 ef2 &&
        eqb_typelist params1 params2 &&
        eqb_type res1 res2 &&
        eqb_calling_convention cc1 cc2
 | _, _ => false
end.


Lemma function_eq_prop: forall f1 f2, function_eq f1 f2 = true -> f1=f2.
Proof.
intros.
unfold function_eq in H.
repeat (revert H; match goal with |- ?A && _ = true -> _ => destruct A eqn:?H; simpl; intro; [ | discriminate] end).
apply eqb_type_true in H.
apply eqb_calling_convention_prop in H4.
destruct (semax_lemmas.eq_dec_statement (Clight.fn_body f1) (Clight.fn_body f2)); try discriminate.
clear H0.
apply (eqb_list_spec _ eqb_member_spec) in H1.
apply (eqb_list_spec _ eqb_member_spec) in H2.
apply (eqb_list_spec _ eqb_member_spec) in H3.
destruct f1,f2; simpl in *; congruence.
Qed.

Lemma fundef_eq_prop: forall fd1 fd2, fundef_eq fd1 fd2 = true -> fd1 = fd2.
Proof.
intros.
destruct fd1, fd2; inv H.
- apply function_eq_prop in H1; congruence.
-
rewrite !andb_true_iff in H1. decompose [and] H1; clear H1.
f_equal.
apply eqb_external_function_prop; auto.
apply eqb_typelist_prop; auto.
apply eqb_type_true; auto.
apply eqb_calling_convention_prop; auto.
Qed.

(*
Definition eqb_init_data (a b: init_data) : bool := 
match a,b with
| Init_int8 i, Init_int8 j => Int.eq i j
| Init_int16 i, Init_int16 j => Int.eq i j
| Init_int32 i, Init_int32 j => Int.eq i j
| Init_int64 i, Init_int64 j => Int64.eq i j
| Init_float32 i, Init_float32 j => Float32.eq_dec i j
| Init_float64 i, Init_float64 j =>Float.eq_dec i j
| Init_space i, Init_space j => Z.eqb i j
| Init_addrof i y, Init_addrof j z => eqb_ident i j && Ptrofs.eq y z
| _, _ => false
end.

Lemma eqb_init_data_prop: forall a b, eqb_init_data a b = true -> a=b.
Proof.
intros.
destruct a,b; try discriminate; f_equal; simpl in H;
try apply Int.same_if_eq in H; auto.
apply Int64.same_if_eq in H; auto.
destruct (Float32.eq_dec f f0); auto; inv H.
destruct (Float.eq_dec f f0); auto; inv H.
apply Z.eqb_eq; auto.
rewrite andb_true_iff in H; destruct H.
apply eqb_ident_spec; auto.
rewrite andb_true_iff in H; destruct H.
apply Ptrofs.same_if_eq; auto.
Qed.
*)

(*
Definition globvar_eq (a b: globvar type) : bool :=
      eqb_type a.(gvar_info) b.(gvar_info) &&
      eqb_list eqb_init_data a.(gvar_init) b.(gvar_init) && 
      bool_eq a.(gvar_readonly) b.(gvar_readonly) &&
      bool_eq a.(gvar_volatile) b.(gvar_volatile).
*)

Definition overlap_Gvar := 
  (* This controls whether we permit linking programs P1 and P2 that both contain
     the same Gvar *)
   false.

Definition isnil {A} (al: list A) := 
   match al with nil => true | _ => false end.

Definition merge_globvar (gv1 gv2: globvar type) : Errors.res (globvar type) :=
 match gv1, gv2 with
 |  {| gvar_info := i1; gvar_init := l1; gvar_readonly := r1; gvar_volatile := v1 |},
    {| gvar_info := i2; gvar_init := l2; gvar_readonly := r2; gvar_volatile := v2 |} =>
   if (overlap_Gvar && 
      (eqb_type i1 i2 &&
      bool_eq r1 r2 &&
      bool_eq v1 v2))%bool
   then if isnil l1 
           then Errors.OK gv2 
           else if isnil l2 then Errors.OK gv1
           else Errors.Error [Errors.MSG "Gvars both initialized"]
   else Errors.Error [Errors.MSG "Gvar type/readonly/volatile clash"]
 end.

Definition merge_globdef (g1 g2: globdef (fundef Clight.function) type) :=
 match g1, g2 with
 | Gfun (External ef1 params1 res1 cc1),
   Gfun (External ef2 params2 res2 cc2) => 
     if fundef_eq (External ef1 params1 res1 cc1)
                        (External ef2 params2 res2 cc2)
     then Errors.OK g1
     else Errors.Error [Errors.MSG "External functions don't match"]
 | Gfun (External e t t0 c), Gfun (Internal f2) => 
     if eqb_signature (signature_of_fundef (External e t t0 c)) (signature_of_fundef (Internal f2))
     then Errors.OK g2
     else Errors.Error [Errors.MSG "function signatures don't match"]
 | Gfun (Internal f1), Gfun (External e t t0 c) =>
     if eqb_signature (signature_of_fundef (Internal f1)) (signature_of_fundef (External e t t0 c))
     then Errors.OK g1
     else Errors.Error [Errors.MSG "function signatures don't match"]
 | Gfun (Internal f), Gfun (Internal g) => 
      if function_eq f g
      then Errors.OK g1
      else Errors.Error [Errors.MSG "internal function clash"]
 | Gvar gv1, Gvar gv2 =>
    Errors.bind (merge_globvar gv1 gv2) (fun gv => Errors.OK (Gvar gv))
  | _, _ => Errors.Error [Errors.MSG "Gvar versus Gfun"]
 end.

Definition eqb_QPbuiltin (a b: QP.builtin) : bool :=
 match a, b with
 | QP.mk_builtin ef1 params1 ty1 cc1, QP.mk_builtin ef2 params2 ty2 cc2 =>
     extspec.extfunct_eqdec ef1 ef2 && eqb_typelist params1 params2 && eqb_type ty1 ty2 
       && eqb_calling_convention cc1 cc2
 end.

Lemma eqb_QPbuiltin_prop: forall a b , eqb_QPbuiltin a b = true -> a=b.
Proof.
destruct a,b; simpl; intros.
rewrite !andb_true_iff in H.
destruct H as [[[??] ?] ?].
destruct (extspec.extfunct_eqdec e e0); inv H.
apply eqb_typelist_prop in H0.
apply eqb_type_true in H1.
apply eqb_calling_convention_prop in H2.
subst; auto.
Qed.

Fixpoint eqb_builtins (al bl: list (ident * QP.builtin)) : bool :=
match al, bl with
| nil, nil => true
| (i,a)::al', (j,b)::bl' => eqb_ident i j && eqb_QPbuiltin a b && eqb_builtins al' bl'
| _, _ => false
end.

Lemma eqb_builtins_prop: forall al bl, eqb_builtins al bl = true -> al=bl.
Proof.
induction al as [|[??]]; destruct bl as [|[??]]; simpl; intros; auto; try discriminate.
rewrite !andb_true_iff in H.
destruct H as [[? ?] ?].
rewrite (proj1 (eqb_ident_spec _ _) H).
apply eqb_QPbuiltin_prop in H0.
subst; f_equal; auto.
Qed.

Lemma eqb_builtins_refl: forall a, eqb_builtins a a = true.
Proof.
induction a as [|[i ?]]; simpl; auto.
rewrite (proj2 (eqb_ident_spec i i) (eq_refl _)).
rewrite IHa; clear.
rewrite andb_true_r. simpl.
destruct b.
simpl.
destruct (extspec.extfunct_eqdec e e); try congruence.
simpl; clear.
rewrite eqb_typelist_refl, eqb_type_refl, eqb_calling_convention_refl.
reflexivity.
Qed.

Definition merge_builtins (al bl: list (ident * QP.builtin)) : 
   Errors.res (list (ident * QP.builtin)) :=
 if eqb_builtins al bl then Errors.OK al else Errors.Error [Errors.MSG "builtins differ"].

Definition QPlink_progs (p1 p2: QP.program Clight.function) : Errors.res (QP.program Clight.function) :=
 Errors.bind (merge_builtins p1.(QP.prog_builtins) p2.(QP.prog_builtins)) (fun builtins =>
 Errors.bind (merge_PTrees merge_globdef (p1.(QP.prog_defs)) p2.(QP.prog_defs)) (fun defs =>
 Errors.bind (merge_consistent_PTrees QPcomposite_eq
                p1.(QP.prog_comp_env) p2.(QP.prog_comp_env)) (fun ce =>
    if eqb_ident p1.(QP.prog_main) p2.(QP.prog_main) then
    Errors.OK 
    {| QP.prog_builtins := builtins;
       QP.prog_defs := defs;
       QP.prog_public := p1.(QP.prog_public) ++ p2.(QP.prog_public);
       QP.prog_main := p1.(QP.prog_main);
       QP.prog_comp_env := ce
     |}
   else Errors.Error [Errors.MSG "QPlink_progs disagreement on main:";
                               Errors.POS p1.(QP.prog_main);
                               Errors.POS p2.(QP.prog_main)]
  ))).

(************************ *)


Lemma linked_compspecs': forall p1 p2 p 
  (OK1:  QPcompspecs_OK (QP.prog_comp_env p1))
  (OK2:  QPcompspecs_OK (QP.prog_comp_env p2))
  (Linked: QPlink_progs p1 p2 = Errors.OK p),
       QPcompspecs_OK (QP.prog_comp_env p)
   /\ PTree_sub (QP.prog_comp_env p1) (QP.prog_comp_env p)
   /\ PTree_sub (QP.prog_comp_env p2) (QP.prog_comp_env p).
Proof.
intros.
unfold QPlink_progs in Linked.
destruct (merge_builtins (QP.prog_builtins p1)
              (QP.prog_builtins p2)); inv Linked.
destruct  (merge_PTrees merge_globdef (QP.prog_defs p1)
          (QP.prog_defs p2)); inv H0.
destruct (merge_consistent_PTrees QPcomposite_eq
          (QP.prog_comp_env p1) (QP.prog_comp_env p2)) eqn:?H; inv H1.
destruct (eqb_ident (QP.prog_main p1) (QP.prog_main p2)); inv H2.
simpl.
split3.
apply  (merged_compspecs' _ _ OK1 OK2 _ H).
-
intros i.
apply (merge_PTrees_e i) in H.
red.
destruct ((QP.prog_comp_env p1) ! i); auto.
destruct ((QP.prog_comp_env p2) ! i); auto.
destruct H as [? [? ?]].
rewrite H0.
destruct (QPcomposite_eq c c0) eqn:?H; inv H.
apply QPcomposite_eq_e in H1; auto.
-
intros i.
apply (merge_PTrees_e i) in H.
red.
destruct ((QP.prog_comp_env p2) ! i); auto.
destruct ((QP.prog_comp_env p1) ! i); auto.
destruct H as [? [? ?]].
rewrite H0.
destruct (QPcomposite_eq c0 c) eqn:?H; inv H.
apply QPcomposite_eq_e in H1; auto.
Qed.

Definition QPglobalenv {F: Type} (p: QP.program F) :=
Genv.add_globals (Genv.empty_genv (fundef F) type (QP.prog_public p))
  (map of_builtin (QP.prog_builtins p) ++ PTree.elements (QP.prog_defs p)).

Fixpoint QPprog_funct' {F} (al: list (ident * globdef (fundef F) type)) : list (ident * fundef F) :=
 match al with
 | nil => nil
 | (i, Gfun f)::al' => (i,f) :: QPprog_funct' al'
 | _::al' => QPprog_funct' al'
end.

Definition QPprog_funct {F} p := @QPprog_funct' F (PTree.elements (QP.prog_defs p)).
 
Fixpoint QPprog_vars' {F} (al: list (ident * globdef (fundef F) type)) : list (ident * globvar type) :=
 match al with
 | nil => nil
 | (i, Gvar v)::al' => (i,v) :: QPprog_vars' al'
 | _::al' => QPprog_vars' al'
end.

Definition QPprog_vars (p: QP.program function) : list (ident * globvar type) :=
 QPprog_vars' (PTree.elements (QP.prog_defs p)).

Definition QPprogram_OK {F} (p: QP.program F) :=
 list_norepet (map fst (QP.prog_builtins p)
                     ++ map fst (PTree.elements (QP.prog_defs p))) /\
 QPcompspecs_OK (QP.prog_comp_env p).

Definition QPlink_progs_OK: 
  forall p1 p2 p,
    QPlink_progs p1 p2 = Errors.OK p ->
    QPprogram_OK p1 ->
    QPprogram_OK p2 ->
    QPprogram_OK p.
Proof.
intros.
destruct H0, H1.
unfold QPlink_progs in H.
Errors.monadInv H.
destruct (eqb_ident (QP.prog_main p1) (QP.prog_main p2)); inv EQ3.
split.
2: apply merged_compspecs' in EQ0; auto.
simpl.
clear - EQ EQ1 H0 H1.
unfold merge_builtins in EQ.
destruct (eqb_builtins (QP.prog_builtins p1) (QP.prog_builtins p2)) eqn:?H; inv EQ.
apply eqb_builtins_prop in H.
rewrite <- H in *.
clear H.
forget (map fst (QP.prog_builtins p1)) as A.
apply list_norepet_app in H0; destruct H0 as [? [? ?]].
apply list_norepet_app in H1; destruct H1 as [? [? ?]].
apply list_norepet_app; split3; auto.
apply PTree.elements_keys_norepet.
intros i j ? ? ?; subst j.
clear - H2 H4 EQ1 H5 H6.
apply (merge_PTrees_e i) in EQ1.
specialize (H2 i i H5).
specialize (H4 i i H5).
apply PTree_In_fst_elements in H6.
destruct H6 as [g ?].
rewrite H in EQ1.
destruct ((QP.prog_defs p1) ! i) eqn:?H.
apply H2; auto.
apply PTree_In_fst_elements; eauto.
destruct ((QP.prog_defs p2) ! i) eqn:?H.
inv EQ1.
apply H4; auto.
apply PTree_In_fst_elements; eauto.
inv EQ1.
Qed.

Lemma QPfind_def_symbol:
  forall {F} p id g,
  QPprogram_OK p ->
  In (id,g) (map of_builtin (QP.prog_builtins p)) \/ (QP.prog_defs p)!id = Some g <-> 
 exists b, Genv.find_symbol (@QPglobalenv F p) id = Some b
   /\ Genv.find_def (@QPglobalenv F p) b = Some g.
Proof.
intros.
unfold QPglobalenv.
transitivity (In (id,g) (map of_builtin (QP.prog_builtins p) ++ PTree.elements (QP.prog_defs p))).
-
rewrite in_app.
split; (intros [?|?]; [left|right]; auto).
apply PTree.elements_correct; auto.
apply PTree.elements_complete; auto.
-
forget (QP.prog_public p) as pubs.
apply proj1 in H.
assert (list_norepet (map fst (map of_builtin (QP.prog_builtins p) ++ PTree.elements (QP.prog_defs p)))).
replace  (map fst (map of_builtin (QP.prog_builtins p) ++ PTree.elements (QP.prog_defs p)))
   with (map fst (QP.prog_builtins p) ++ map fst (PTree.elements (QP.prog_defs p))); auto.
rewrite map_app.
f_equal.
rewrite map_map.
f_equal.
extensionality x. destruct x as [i b]. destruct b; reflexivity.
clear H; rename H0 into H.
forget (map of_builtin (QP.prog_builtins p) ++ PTree.elements (QP.prog_defs p)) as al.
clear p.
unfold Genv.add_globals.
split; intro.
+
forget (Genv.empty_genv (fundef F) type pubs) as ge.
revert ge; induction al as [|[i d]]; simpl; intros.
inv H0.
inv H.
simpl in H0.
destruct H0.
*
inv H.
clear IHal.
clear - H3.
assert (exists b : block,
  Genv.find_symbol ((Genv.add_global ge (id, g))) id = Some b /\
  Genv.find_def ((Genv.add_global ge (id, g))) b = Some g). {
  eexists; split. apply PTree.gss. apply PTree.gss.
}
set (ge' := Genv.add_global ge (id, g)) in *.
change (Genv.add_global ge (id, g)) with ge'.
clearbody ge'.
revert ge' H ; induction al as [|[i d]]; simpl; intros; auto.
assert (~In id (map fst al)) by (contradict H3; right; auto).
assert (id<>i) by (contradict H3; subst; left; auto).
apply IHal; clear IHal; auto.
destruct H as [b [? ?]].
exists b.
unfold Genv.find_symbol, Genv.find_def in *; simpl in *.
rewrite PTree.gso by auto.
split; auto.
rewrite PTree.gso; auto.
intro; subst.
pose proof (Genv.genv_symb_range _ _ H).
red in H4. lia.
*
apply (IHal H4 H (Genv.add_global ge (i, d))).
+
assert (In (id,g) al \/ 
           exists b, Genv.find_symbol
               (Genv.empty_genv (fundef F) type pubs) id = Some b /\
               Genv.find_def (Genv.empty_genv (fundef F) type pubs) b = 
       Some g).
2:{ destruct H1; auto. destruct H1 as [? [? ?]]. unfold Genv.find_symbol in H1; simpl in H1.
               rewrite PTree.gempty in H1; inv H1.
}
forget  (Genv.empty_genv (fundef F) type pubs) as ge.
revert ge H0; induction al as [|[j c]]; simpl; intros.
destruct H0 as [b [? ?]]; right; exists b; auto.
inv H.
apply IHal in H0; clear IHal; auto.
destruct H0.
left. right. auto.
destruct H as [b [? ?]].
destruct (ident_eq j id).
subst.
unfold Genv.find_def, Genv.find_symbol in *; simpl in *.
rewrite PTree.gss in H. inv H. rewrite PTree.gss in H0. inv H0; auto.
right.
unfold Genv.find_def, Genv.find_symbol in *; simpl in *.
rewrite PTree.gso in H by auto.
exists b; split; auto.
rewrite PTree.gso in H0; auto.
intro.
subst.
pose proof (Genv.genv_symb_range _ _ H).
red in H1. lia.
Qed.

Lemma QPfind_funct_ptr_exists:
forall (p: QP.program Clight.function) i f,
  QPprogram_OK p ->
(QP.prog_defs p) ! i = Some (Gfun f) ->
exists b,
 Genv.find_symbol (QPglobalenv p) i = Some b
/\ Genv.find_funct_ptr (QPglobalenv p) b = Some f.
Proof.
intros.
destruct (proj1 (QPfind_def_symbol p i (Gfun f) H) (or_intror H0))
as [b [? ?]].
exists b; split; auto.
unfold Genv.find_funct_ptr.
rewrite H2.
auto.
Qed.

Lemma QPprogram_of_program_OK:
  forall {F} (p: program F) (cs: compspecs),
  list_norepet (map fst (prog_defs p)) ->
  @cenv_cs cs = prog_comp_env p ->
  PTree_samedom (@cenv_cs cs) (@ha_env_cs cs) ->
  PTree_samedom (@cenv_cs cs) (@la_env_cs cs) ->
   QPprogram_OK (QPprogram_of_program p (@ha_env_cs cs) (@la_env_cs cs)).
Proof.
intros.
split.
-
clear - H.
apply list_norepet_app.
split3.
+
simpl.
induction (prog_defs p).
constructor.
inv H.
destruct a.
destruct g; simpl; auto.
destruct f; simpl; auto.
simpl in H2.
assert (~ In i (map fst (filter_options is_builtin l))). {
 clear - H2; contradict H2; induction l; simpl; auto.
 destruct a; simpl in *; auto. destruct g; simpl in *; auto.
 destruct f; simpl in *; auto. destruct e; simpl in *; auto.
 destruct H2; auto. destruct H2; auto.
}
destruct e; simpl; auto;
constructor; auto.
+
apply PTree.elements_keys_norepet.
+
intros i j ? ? ?; subst j.
apply PTree_In_fst_elements in H1.
destruct H1 as [g ?].
simpl in *.
apply PTree_Properties.in_of_list in H1.
apply filter_In in H1.
destruct H1.
apply list_in_map_inv in H0.
destruct H0 as [[j g'] [? ?]].
simpl in H0; subst j.
induction (prog_defs p) as [|[j ?]].
inv H1.
simpl in *.
inv H.
destruct H1.
inv H.
destruct g.
destruct f.
apply H5.
clear - H3.
induction l; simpl in *; auto.
destruct a; auto.
destruct g; auto.
simpl in *.
destruct f; auto.
destruct e; auto; destruct H3; auto; inv H; auto.
unfold not_builtin in H2.
fold (@is_builtin function (i, Gfun (External e t t0 c))) in H3.
revert H2; destruct (is_builtin _) eqn:?H; intro H2; inv H2.
apply H5.
clear - H3.
induction l; simpl in *; auto.
destruct a; auto.
destruct g; auto.
simpl in *.
destruct f; auto.
destruct e; auto; destruct H3; auto; inv H; auto.
apply H5.
clear - H3.
induction l; simpl in *; auto.
destruct a; auto.
destruct g; auto.
simpl in *.
destruct f; auto.
destruct e; auto; destruct H3; auto; inv H; auto.
destruct g0; auto.
destruct f; auto.
destruct e; auto.
simpl in H3. destruct H3; auto.
inv H0.
apply H5.
apply (in_map fst) in H. apply H.
simpl in H3. destruct H3; auto.
inv H0.
apply H5.
apply (in_map fst) in H. apply H.
-
clear H.
simpl.
rewrite <- H0.
clear - H1 H2.
apply QPcompspecs_OK_i; auto.
Qed.


Lemma QPlink_progs_globdefs: (* move this to quickprogram.v *)
 forall p1 p2 p, 
  QPlink_progs p1 p2 = Errors.OK p ->
   merge_PTrees merge_globdef (QP.prog_defs p1) (QP.prog_defs p2) = 
    Errors.OK (QP.prog_defs p).
Proof.
clear.
intros.
unfold QPlink_progs in H.
Errors.monadInv H.
destruct (eqb_ident (QP.prog_main p1) (QP.prog_main p2));
inv EQ3.
auto.
Qed.

Lemma rebuild_composite_env:
  forall (ce: QP.composite_env) (OK: QPcomposite_env_OK ce),
 build_composite_env
    (map compdef_of_compenv_element (sort_rank (PTree.elements ce) [])) =
  Errors.OK (composite_env_of_QPcomposite_env ce OK).
Proof.
Admitted.  (* Probably true, but we'll work around it for now *)

Definition is_builtin' (ix: ident * QP.builtin) :=
 match ix with
 | (_, QP.mk_builtin (EF_builtin _ _)  _ _ _) => true
 | (_, QP.mk_builtin (EF_runtime _ _) _ _ _) => true
 | (_, _) => false
end.

Module Junkyard.

Fixpoint QPcomplete_type (env : QP.composite_env) (t : type) :  bool :=
  match t with
  | Tarray t' _ _ => QPcomplete_type env t'
  | Tvoid | Tfunction _ _ _ => false
  | Tstruct id _ | Tunion id _ =>
      match env ! id with
      | Some _ => true
      | None => false
      end
  | _ => true
  end.

Fixpoint QPcomplete_members (e: QP.composite_env) (m: members) :=
 match m with
 | nil => true
 | (_,t)::m' => QPcomplete_type e t && QPcomplete_members e m'
 end.

Definition QPcomposite_env_complete (e: QP.composite_env) : Prop :=
  PTree_Forall (fun c => QPcomplete_members e (QP.co_members c) = true) e.

Lemma build_composite_env_helper :
 forall ce
  (H: QPcomposite_env_OK ce)
(*  (Hcomplete: QPcomposite_env_complete ce) *),
  build_composite_env
    (map compdef_of_compenv_element
       (PTree.elements ce)) =
  Errors.OK
    (composite_env_of_QPcomposite_env ce H).
Proof.
Abort.

(*
Definition program_of_QPprogram {F} (p: QP.program F) 
  (H: QPcomposite_env_OK (p.(QP.prog_comp_env)))
  (H0: QPcomposite_env_complete (p.(QP.prog_comp_env)))
   : Ctypes.program F  :=
 {| prog_defs := PTree.elements p.(QP.prog_defs);
    prog_public := p.(QP.prog_public);
    prog_main := p.(QP.prog_main);
    prog_types := map compdef_of_compenv_element 
                             (sort_rank (PTree.elements (p.(QP.prog_comp_env))) nil);
    prog_comp_env := composite_env_of_QPcomposite_env p.(QP.prog_comp_env) H;
    prog_comp_env_eq := 8 
 |}.
*)

End Junkyard.















