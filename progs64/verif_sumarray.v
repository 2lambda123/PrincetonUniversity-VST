(* Do not edit this file, it was generated automatically *)
Require Import VST.floyd.proofauto. (* Import the Verifiable C system *)
Require Import VST.progs64.sumarray. (* Import the AST of this C program *)
(* The next line is "boilerplate", always required after importing an AST. *)
#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs.  mk_varspecs prog. Defined.

(* Functional spec of this program.  *)
Definition sum_Z : list Z -> Z := fold_right Z.add 0.

Lemma sum_Z_app:
  forall a b, sum_Z (a++b) =  sum_Z a + sum_Z b.
Proof.
  intros. induction a; simpl; lia.
Qed.

Section Spec.

Context  `{!default_VSTGS Σ}.

Definition sumarray_spec : ident * funspec :=
 DECLARE _sumarray
  WITH a: val, sh : share, contents : list Z, size: Z
  PRE [ (tptr tuint), tint ]
          PROP  (readable_share sh; 0 <= size <= Int.max_signed;
                 Forall (fun x => 0 <= x <= Int.max_unsigned) contents)
          PARAMS (a; Vint (Int.repr size))
          GLOBALS ()
          SEP   (data_at sh (tarray tuint size) (map Vint (map Int.repr contents)) a)
  POST [ tuint ]
        PROP () LOCAL(temp ret_temp  (Vint (Int.repr (sum_Z contents))))
           SEP (data_at sh (tarray tuint size) (map Vint (map Int.repr contents)) a).

(* Note: It would also be reasonable to let [contents] have type [list int].
  Then the [Forall] would not be needed in the PROP part of PRE.
*)

(* The precondition of "int main(void){}" always looks like this. *)
Definition main_spec :=
 DECLARE _main
  WITH gv : globals
  PRE  [] main_pre prog tt gv
  POST [ tint ]  
     PROP() 
     LOCAL (temp ret_temp (Vint (Int.repr (1+2+3+4)))) 
     SEP(True).

(* Note: It would also be reasonable to let [contents] have type [list int].
  Then the [Forall] would not be needed in the PROP part of PRE.
*)

(* Packaging the API spec all together. *)
Definition Gprog : funspecs :=
        ltac:(with_library prog [sumarray_spec; main_spec]).

(** Proof that f_sumarray, the body of the sumarray() function,
 ** satisfies sumarray_spec, in the global context (Vprog,Gprog).
 **)
Lemma body_sumarray: semax_body Vprog Gprog ⊤ f_sumarray sumarray_spec.
Proof.
start_function. (* Always do this at the beginning of a semax_body proof *)
(* The next two lines do forward symbolic execution through
   the first two executable statements of the function body *)
forward.  (* i = 0; *)
forward.  (* s = 0; *)
(* To do symbolic execution through a [while] loop, we must
 * provide a loop invariant, so we use [forward_while] with
 * the invariant as an argument .*)
forward_while
 (∃ i: Z,
   PROP  (0 <= i <= size)
   LOCAL (temp _a a;
          temp _i (Vint (Int.repr i));
          temp _n (Vint (Int.repr size));
          temp _s (Vint (Int.repr (sum_Z (sublist 0 i contents)))))
   SEP   (data_at sh (tarray tuint size) (map Vint (map Int.repr contents)) a)).
(* forward_while leaves four subgoals; here we label them
   with the * bullet. *)
* (* Prove that current precondition implies loop invariant *)
Exists 0.   (* Instantiate the existential on the right-side of |--   *)
entailer!.  (* Simplify this entailment as much as possible; in this
      case, it solves entirely; in other cases, entailer! leaves subgoals *)
* (* Prove that loop invariant implies typechecking condition *)
entailer!.  (* Typechecking conditions usually solve quite easily *)
* (* Prove postcondition of loop body implies loop invariant *)
(* In order to get to the postcondition of the loop body, of course,
   we must forward-symbolic-execute through the loop body;
   so we start that here. *)
(* "forward" fails and tells us to first make (0 <= i < Zlength contents)
   provable by auto, so we assert the following: *)
assert_PROP (Zlength contents = size). {
  entailer!. do 2 rewrite Zlength_map. reflexivity.
}
forward. (* x = a[i] *)
forward. (* s += x; *) 
forward. (* i++; *) 
 (* Now we have reached the end of the loop body, and it's
   time to prove that the _current precondition_  (which is the
   postcondition of the loop body) entails the loop invariant. *)
 Exists (i+1).  simpl.
 entailer!. simpl.
 f_equal.
 rewrite ->(sublist_split 0 i (i+1)) by lia.
 rewrite sum_Z_app. rewrite ->(sublist_one i) by lia.
 autorewrite with sublist. normalize.
 simpl. rewrite Z.add_0_r. reflexivity.
* (* After the loop *)
forward.  (* return s; *)
 (* Here we prove that the postcondition of the function body
    entails the postcondition demanded by the function specification. *)
entailer!.
autorewrite with sublist in *.
autorewrite with sublist.
reflexivity.
Qed.

(* Contents of the extern global initialized array "_four" *)
Definition four_contents := [1; 2; 3; 4].


Lemma body_main:  semax_body Vprog Gprog ⊤ f_main main_spec.
Proof.
start_function.


(* Ltac new_fwd_call' := *)

(* lazymatch goal with
| |- semax _ _ _ (Ssequence (Ssequence (Scall (Some ?ret') _ _)
                                       (Sset _ (Etempvar ?ret'2 _))) _) _ =>
                                       idtac "C";
       unify ret' ret'2;
       eapply semax_seq';
         [new_prove_call_setup;
          clear_Delta_specs; clear_MORE_POST;
             [ .. | forward_call_id1_y_wow ]
         |  after_forward_call ]
         | |- _ => rewrite <- seq_assoc; new_fwd_call'
end.
new_fwd_call' (gv _four, Ews,four_contents,4). *)


(* fwd_call_dep (@nil Type) . *)
try lazymatch goal with
      | |- semax _ _ _ (Scall _ _ _) _ => rewrite -> semax_seq_skip
      end;
 repeat lazymatch goal with
  | |- semax _ _ _ (Ssequence (Ssequence (Ssequence _ _) _) _) _ =>
      rewrite <- seq_assoc
 end.
 (* fwd_call' funspec_sub_refl  (gv _four, Ews,four_contents,4). *)
 check_POSTCONDITION;
 lazymatch goal with
 | |- semax _ _ _ (Ssequence (Ssequence (Scall (Some ?ret') _ _)
                                        (Sset _ (Etempvar ?ret'2 _))) _) _ =>
        unify ret' ret'2;
        eapply semax_seq'
        (* ;
          [prove_call_setup (*ts*) funspec_sub_refl  (gv _four, Ews,four_contents,4);
           clear_Delta_specs; clear_MORE_POST;
              [ .. | forward_call_id1_y_wow ]
          |  after_forward_call ] *)
 | |- _ => rewrite <- seq_assoc; fwd_call' (*ts*) funspec_sub_refl  (gv _four, Ews,four_contents,4)
 end.

- 




Ltac check_subsumes subsumes :=
  unfold NDmk_funspec;
  lazymatch goal with |- funspec_sub _ (mk_funspec _ _ ?A1 _ _) (mk_funspec _ _ ?A2 _ _) =>
  unify A1 A2
  end;
 apply subsumes ||
 lazymatch goal with |- ?g =>
 lazymatch type of subsumes with ?t =>
  fail 100 "Function-call subsumption fails.  The term" subsumes "of type" t
     "does not prove the funspec_sub," g
 end end.

(* prove_call_setup funspec_sub_refl  (gv _four, Ews,four_contents,4). *)
(* prove_call_setup1 funspec_sub_refl. *)
 match goal with
| |- @semax _ _ _ _ ?CS ?E ?Delta (PROPx ?P (LOCALx ?Q (SEPx ?R'))) ?c _ =>
  let cR := (fun R =>
  match c with
  | context [Scall _ (Evar ?id ?ty) ?bl] =>
    exploit (call_setup1_i2 E Delta P Q R' id ty bl) ;
    [check_prove_local2ptree
    | apply can_assume_funcptr2;
      [ check_function_name
      | lookup_spec id
      | find_spec_in_globals'
      | check_type_of_funspec id
      ]
    |
    check_subsumes funspec_sub_refl
    | 
    try reflexivity; (eapply classify_fun_ty_hack; [apply funspec_sub_refl| reflexivity ..])
    |
    check_typecheck
    |
    check_typecheck
    |
    check_cast_params
    | ..
    ]
  end)
  in strip1_later R' cR
end.


Ltac prove_call_setup_aux  (*ts*) witness :=
 let H := fresh "SetupOne" in
 intro H;
 match goal with | |- @semax _ _ _ _ ?CS _ _ (PROPx ?P (LOCALx ?L (SEPx ?R'))) _ _ =>
 let Frame := fresh "Frame" in evar (Frame: list mpred); 
 let cR := (fun R =>
 exploit (call_setup2_i _ _ _ _ _ _ _ _ R R' _ _ _ _ (*ts*) _ _ _ _ _  H witness Frame); clear H;
 [ try_convertPreElim
 | check_prove_local2ptree
 | check_vl_eq_args
 | auto 50 with derives
 | check_gvars_spec
 | try change_compspecs CS; cancel_for_forward_call
 |
 ])
  in strip1_later R' cR
 end.

 prove_call_setup_aux (*ts*) (gv _four, Ews,four_contents,4).

 (* new_prove_call_setup. *)
          clear_Delta_specs; clear_MORE_POST.


          (* Ltac forward_call_id1_y_wow := *)
let H := fresh in intro H;
eapply (semax_call_id1_y_wow H); 
 clear H;
 lazymatch goal with Frame := _ : list mpred |- _ => try clear Frame end;
 [ check_result_type | check_result_type
 | apply Coq.Init.Logic.I | apply Coq.Init.Logic.I | reflexivity
 | (clear; let H := fresh in intro H; inversion H)
 | 
 (* match_postcondition *)
 | prove_delete_temp
 | prove_delete_temp
 | unify_postcondition_exps
 | prove_PROP_preconditions
 ].



(* Ltac unfold_post :=
match goal with |- ?Post ⊣⊢ _ => let A := fresh "A" in let B := fresh "B" in first
  [evar (A : Type); evar (B : A -> environ -> mpred); unify Post (@bi_exist _ ?A ?B);
     change Post with (@bi_exist _ A B); subst A B |
   evar (A : list Prop); evar (B : environ -> mpred); unify Post (PROPx ?A ?B);
     change Post with (PROPx A B); subst A B | idtac] end. *)

     Set Nested Proofs Allowed.
    Lemma PROP_LOCAL_SEP_ext' :
  forall {Σ:gFunctors} P P' Q Q' R R', P=P' -> Q=Q' -> R=R' -> 
     PROPx P (LOCALx Q (SEPx R)) ⊣⊢ PROPx(Σ:=Σ) P' (LOCALx Q' (SEPx R')).
Proof.
intros; subst; auto.
Qed.

Ltac unfold_post := match goal with |- ?Post ⊣⊢ _ => let A := fresh "A" in let B := fresh "B" in first
  [evar (A : Type); evar (B : A -> environ -> mpred); unify Post (@bi_exist _ ?A ?B);
     change Post with (@bi_exist _ A B); subst A B |
   evar (A : list Prop); evar (B : environ -> mpred); unify Post (PROPx ?A ?B);
     change Post with (PROPx A B); subst A B | idtac] end.

     Ltac match_postcondition:=
      fix_up_simplified_postcondition;
     cbv beta iota zeta; unfold_post; 
        (* extensionality rho. *) constructor; let rho := fresh "rho" in intro rho; cbn; 
   repeat rewrite exp_uncurry;
   try rewrite no_post_exists; repeat rewrite monPred_at_exist;
tryif apply bi.exist_proper
 then (intros ?vret;
          (* apply equal_f;
          apply PROP_LOCAL_SEP_ext;  *)
          generalize rho; rewrite -local_assert; apply PROP_LOCAL_SEP_ext'
          ;
          [reflexivity | | reflexivity];
          (reflexivity) 
          )
 else idtac.

match_postcondition.
    repeat constructor; computable.
    - simpl. forward. (* return s; *)


forward_call (*  s = sumarray(four,4); *)
  (gv _four, Ews,four_contents,4).
 repeat constructor; computable.
forward. (* return s; *)
Qed.

#[export] Existing Instance NullExtension.Espec.

Lemma prog_correct:
  semax_prog prog tt Vprog Gprog.
Proof.
  prove_semax_prog.
  semax_func_cons body_sumarray.
  semax_func_cons body_main.
Qed.
