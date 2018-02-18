Require Import VST.floyd.base2.
Require Import VST.floyd.client_lemmas.
Require Import VST.floyd.nested_field_lemmas.
Require Import VST.floyd.efield_lemmas.
Require Import VST.floyd.reptype_lemmas.
Require Import VST.floyd.proj_reptype_lemmas.
Require Import VST.floyd.replace_refill_reptype_lemmas.
Require Import VST.floyd.mapsto_memory_block.
Require Import VST.floyd.data_at_rec_lemmas.
Require Import VST.floyd.field_at.
Require Import VST.floyd.stronger.
Require Import VST.floyd.entailer.
Require Import VST.floyd.closed_lemmas.
Require Import VST.floyd.loadstore_mapsto.
Require Import VST.floyd.loadstore_field_at.
Require Import VST.floyd.nested_loadstore.
Require Import VST.floyd.local2ptree_denote.
Require Import VST.floyd.local2ptree_eval.
Require Import VST.floyd.simpl_reptype.

Local Open Scope logic.

Section SEMAX_SC.

Context {cs: compspecs}.

Lemma semax_SC_set:
  forall {Espec: OracleKind},
    forall Delta id P Q R (e2: expr) t v,
      typeof_temp Delta id = Some t ->
      is_neutral_cast (implicit_deref (typeof e2)) t = true ->
      ENTAIL Delta, PROPx P (LOCALx Q (SEPx R)) |-- local (`(eq v) (eval_expr e2)) ->
      ENTAIL Delta, PROPx P (LOCALx Q (SEPx R)) |--
         (tc_expr Delta e2) ->
      semax Delta (|>PROPx P (LOCALx Q (SEPx R)))
        (Sset id e2)
          (normal_ret_assert
            (PROPx P
              (LOCALx (temp id v :: remove_localdef_temp id Q)
                (SEPx R)))).
Proof.
  intros.
  assert (ENTAIL Delta, PROPx P (LOCALx Q (SEPx R)) |--
     (tc_expr Delta e2) &&  (tc_temp_id id (typeof e2) Delta e2)).
  {
    apply andp_right.
    + eapply derives_trans; [exact H2 | apply derives_refl].
    + unfold tc_temp_id.
      unfold typecheck_temp_id.
      unfold typeof_temp in H.
      destruct ((temp_types Delta) ! id) as [[? ?]|]; [| inversion H].
      inversion H; clear H; subst.
      rewrite H0.
      simpl denote_tc_assert; simpl; intros.
      unfold local, lift1.
      apply neutral_isCastResultType, H0.
  }
  eapply semax_pre_simple.
  {
    hoist_later_left.
    rewrite (add_andp _ _ H3).
    rewrite andp_comm.
    rewrite (add_andp _ _ H1).
    apply later_derives.
    apply andp_derives; [apply derives_refl |].
    apply andp_derives; [| apply derives_refl].
    apply andp_left2.
    apply derives_refl.
  }
  eapply semax_post'; [| apply semax_set_forward].
  apply andp_left2; 
  rewrite <- insert_local.
  eapply derives_trans; [| apply andp_derives; [apply derives_refl | apply remove_localdef_temp_PROP]].
  normalize.
  apply (exp_right old).
  autorewrite with subst.
  rewrite andp_comm, andp_assoc, andp_comm.
  apply andp_derives; auto.
  simpl; unfold local, lift1; unfold_lift; intro rho; simpl.
  normalize.
Qed.

Lemma semax_SC_field_load:
  forall {Espec: OracleKind} n (Delta: tycontext) sh id P Q R e1
    t_id t_root gfs0 gfs1 gfs (p v_val: val) (v_reptype: reptype (nested_field_type t_root gfs0)),
    typeof e1 = nested_field_type t_root gfs ->
    typeof_temp Delta id = Some t_id ->
    is_neutral_cast (nested_field_type t_root gfs) t_id = true ->
    type_is_volatile (nested_field_type t_root gfs) = false ->
    ENTAIL Delta, PROPx P (LOCALx Q (SEPx R)) |--
       local (`(eq (field_address t_root gfs p)) (eval_lvalue e1)) ->
    nth_error R n = Some (field_at sh t_root gfs0 v_reptype p) ->
    gfs = gfs1 ++ gfs0 ->
    readable_share sh ->
    JMeq (proj_reptype (nested_field_type t_root gfs0) gfs1 v_reptype) v_val ->
    ENTAIL Delta, PROPx P (LOCALx Q (SEPx R)) |--
      (tc_lvalue Delta e1) && local (`(tc_val (nested_field_type t_root gfs) v_val)) ->
    @semax cs Espec Delta (|> PROPx P (LOCALx Q (SEPx R)))
      (Sset id e1)
      (normal_ret_assert
         (PROPx P
           (LOCALx (temp id v_val :: remove_localdef_temp id Q)
             (SEPx R)))).
Proof.
  intros.
  assert_PROP (field_compatible t_root gfs p).
  Focus 1. {
    rewrite (add_andp _ _ H8), (add_andp _ _ H3).
    apply derives_trans with (local (tc_environ Delta) && local (` (eq (field_address t_root gfs p)) (eval_lvalue e1)) && (tc_lvalue Delta e1)); [solve_andp |].
    unfold local, lift1; intros rho; simpl; unfold_lift.
    normalize.
    eapply derives_trans; [apply typecheck_lvalue_sound; auto |].
    rewrite <- H10; normalize.
  } Unfocus.
  subst gfs.
  pose proof nested_field_ramif_load sh _ _ _ _ _ _ H9 H7 as [v_reptype' [? ?]].
  eapply semax_load_nth_ram_field_at.
  1: eassumption.
  1: eassumption.
  1: eassumption.
  1: eassumption.
  1: eassumption.
  1: eassumption.
  1: eassumption.
  1: eassumption.
  1: eassumption.
  1: eassumption.
Qed.

Lemma nth_error_SEP_sepcon_TT': forall D P Q R n Rn S,
  ENTAIL D, PROPx P (LOCALx Q (SEPx (Rn :: nil))) |-- S ->
  nth_error R n = Some Rn ->
  ENTAIL D, (PROPx P (LOCALx Q (SEPx R))) |-- S * TT.
Proof.
  intros.
  erewrite SEP_nth_isolate by eauto.
  unfold PROPx, LOCALx, SEPx in *.
  unfold local, lift1 in H |- *.
  unfold_lift in H.
  unfold_lift.
  simpl in H |- *.
  intros rho.
  specialize (H rho).
  rewrite <- !andp_assoc in H |- *.
  rewrite <- !prop_and in H |- *.
  rewrite sepcon_emp in H.
  rewrite <- sepcon_andp_prop'.
  apply sepcon_derives.
  exact H.
  apply prop_right.
  auto.
Qed.

Lemma semax_SC_field_cast_load:
  forall {Espec: OracleKind} n (Delta: tycontext) sh id P Q R e1 t
    t_root gfs0 gfs1 gfs (p v_val: val) (v_reptype: reptype (nested_field_type t_root gfs0)),
    typeof e1 = nested_field_type t_root gfs ->
    typeof_temp Delta id = Some t ->
    type_is_by_value (nested_field_type t_root gfs) = true ->
    cast_pointer_to_bool (nested_field_type t_root gfs) t = false ->
    type_is_volatile (nested_field_type t_root gfs) = false ->
    ENTAIL Delta, PROPx P (LOCALx Q (SEPx R)) |--
       local (`(eq (field_address t_root gfs p)) (eval_lvalue e1)) ->
    nth_error R n = Some (field_at sh t_root gfs0 v_reptype p) ->
    gfs = gfs1 ++ gfs0 ->
    readable_share sh ->
    JMeq (proj_reptype (nested_field_type t_root gfs0) gfs1 v_reptype) v_val ->
    ENTAIL Delta, PROPx P (LOCALx Q (SEPx R)) |--
      (tc_lvalue Delta e1) && local (`(tc_val t (eval_cast (nested_field_type t_root gfs) t v_val))) ->
    @semax cs Espec Delta (|> PROPx P (LOCALx Q (SEPx R)))
      (Sset id (Ecast e1 t))
      (normal_ret_assert
         (PROPx P
           (LOCALx (temp id (eval_cast (nested_field_type t_root gfs) t v_val) :: remove_localdef_temp id Q)
             (SEPx R)))).
Proof.
  intros.
  assert_PROP (field_compatible t_root gfs p).
  Focus 1. {
    rewrite (add_andp _ _ H9), (add_andp _ _ H4).
    apply derives_trans with (local (tc_environ Delta) && local (` (eq (field_address t_root gfs p)) (eval_lvalue e1)) && (tc_lvalue Delta e1)); [solve_andp |].
    unfold local, lift1; intros rho; simpl; unfold_lift.
    normalize.
    eapply derives_trans; [apply typecheck_lvalue_sound; auto |].
    rewrite <- H11; normalize.
  } Unfocus.
  subst gfs.
  pose proof nested_field_ramif_load sh _ _ _ _ _ _ H10 H8 as [v_reptype' [? ?]].
  eapply semax_cast_load_nth_ram_field_at.
  1: eassumption.
  1: eassumption.
  1: eassumption.
  1: eassumption.
  1: eassumption.
  1: eassumption.
  1: eassumption.
  1: eassumption.
  1: eassumption.
  1: eassumption.
  1: eassumption.
Qed.

Lemma semax_SC_field_store:
  forall {Espec: OracleKind},
    forall Delta sh n (p: val) P Q R (e1 e2 : expr)
      (t_root: type) (gfs0 gfs1 gfs: list gfield)
      (v0: reptype (nested_field_type (nested_field_type t_root gfs0) gfs1))
      (v0_val: val) (v v_new: reptype (nested_field_type t_root gfs0)),
      typeof e1 = nested_field_type t_root gfs ->
      type_is_by_value (nested_field_type t_root gfs) = true ->
      type_is_volatile (nested_field_type t_root gfs) = false ->
      gfs = gfs1 ++ gfs0 ->
      nth_error R n = Some (field_at sh t_root gfs0 v p) ->
      ENTAIL Delta, PROPx P (LOCALx Q (SEPx R)) |--
        local (`(eq (field_address t_root gfs p)) (eval_lvalue e1)) ->
      ENTAIL Delta, PROPx P (LOCALx Q (SEPx R)) |--
        local (`(eq v0_val) (eval_expr (Ecast e2 (nested_field_type t_root gfs)))) ->
      writable_share sh ->
      JMeq v0 v0_val ->
      data_equal (upd_reptype (nested_field_type t_root gfs0) gfs1 v v0) v_new ->
      ENTAIL Delta, PROPx P (LOCALx Q (SEPx R)) |--
         (tc_lvalue Delta e1) && 
         (tc_expr Delta (Ecast e2 (nested_field_type t_root gfs))) ->
      semax Delta (|>PROPx P (LOCALx Q (SEPx R)))
        (Sassign e1 e2)
          (normal_ret_assert
            (PROPx P
              (LOCALx Q
                (SEPx
                  (replace_nth n R
                    (field_at sh t_root gfs0 v_new p)))))).
Proof.
  intros.
  erewrite field_at_data_equal by (symmetry; apply H8).
  clear H8 v_new.
  assert_PROP (field_compatible t_root gfs p).
  Focus 1. {
    rewrite (add_andp _ _ H9), (add_andp _ _ H4).
    apply derives_trans with (local (tc_environ Delta) && local (` (eq (field_address t_root gfs p)) (eval_lvalue e1)) && (tc_lvalue Delta e1)); [solve_andp |].
    unfold local, lift1; intros rho; simpl; unfold_lift.
    normalize.
    eapply derives_trans; [apply typecheck_lvalue_sound; auto |].
    rewrite <- H10; normalize.
  } Unfocus.
  subst gfs.
  pose proof nested_field_ramif_store sh _ _ _ v _ _ _ H8 H7 as [v_reptype' [? ?]].
  eapply semax_store_nth_ram_field_at.
  1: eassumption.
  1: eassumption.
  1: eassumption.
  1: eassumption.
  1: eassumption.
  1: apply @JMeq_sym. eassumption.
  1: eassumption.
  1: eassumption.
  1: eassumption.
  rewrite (add_andp _ _ H9), (add_andp _ _ H5); solve_andp.
Qed.

End SEMAX_SC.

(************************************************

The set, load, cast-load and store rules will be used in the future.

************************************************)

Inductive Int_eqm_unsigned: int -> Z -> Prop :=
| Int_eqm_unsigned_repr: forall z, Int_eqm_unsigned (Int.repr z) z.

Lemma Int_eqm_unsigned_spec: forall i z,
  Int_eqm_unsigned i z -> Int.eqm (Int.unsigned i) z.
Proof.
  intros.
  inv H.
  apply Int.eqm_sym, Int.eqm_unsigned_repr.
Qed.

Ltac solve_Int_eqm_unsigned :=
  solve
  [ autorewrite with norm;
    match goal with
    | |- Int_eqm_unsigned ?V _ =>
      match V with
      | Int.repr _ => idtac
      | Int.sub _ _ => unfold Int.sub at 1
      | Int.add _ _ => unfold Int.add at 1
      | Int.mul _ _ => unfold Int.mul at 1
      | Int.and _ _ => unfold Int.and at 1
      | Int.or _ _ => unfold Int.or at 1
(*      | Int.shl _ _ => unfold Int.shl at 1
      | Int.shr _ _ => unfold Int.shr at 1*)
      | _ => rewrite <- (Int.repr_unsigned V) at 1
      end
    end;
    apply Int_eqm_unsigned_repr
  ].

Inductive msubst_efield_denote {cs: compspecs} (T1: PTree.t val) (T2: PTree.t vardesc): list efield -> list gfield -> Prop :=
| msubst_efield_denote_nil: msubst_efield_denote T1 T2 nil nil
| msubst_efield_denote_cons_array: forall ei i i' efs gfs,
    is_int_type (typeof ei) = true ->
    msubst_eval_expr T1 T2 ei = Some (Vint i) ->
    Int_eqm_unsigned i i' ->
    msubst_efield_denote T1 T2 efs gfs ->
    msubst_efield_denote T1 T2 (eArraySubsc ei :: efs) (ArraySubsc i' :: gfs)
| msubst_efield_denote_cons_struct: forall i efs gfs,
    msubst_efield_denote T1 T2 efs gfs ->
    msubst_efield_denote T1 T2 (eStructField i :: efs) (StructField i :: gfs)
| msubst_efield_denote_cons_union: forall i efs gfs,
    msubst_efield_denote T1 T2 efs gfs ->
    msubst_efield_denote T1 T2 (eUnionField i :: efs) (UnionField i :: gfs).

Lemma msubst_efield_denote_eq: forall {cs: compspecs} P T1 T2 Q R efs gfs,
  msubst_efield_denote T1 T2 efs gfs ->
  PROPx P (LOCALx (LocalD T1 T2 Q) (SEPx R)) |-- local (efield_denote efs gfs).
Proof.
  intros ? ? ? ? ? ? ? ? MSUBST_EFIELD_DENOTE.
  induction MSUBST_EFIELD_DENOTE.
  + intro rho; apply prop_right; constructor.
  + eapply (msubst_eval_expr_eq P _ _ Q R) in H0.
    rewrite (add_andp _ _ H0), (add_andp _ _ IHMSUBST_EFIELD_DENOTE).
    clear H0 IHMSUBST_EFIELD_DENOTE.
    rewrite andp_assoc; apply andp_left2.
    unfold local, lift1; unfold_lift; intro rho; simpl.
    normalize.
    constructor; auto.
    constructor.
    apply Int_eqm_unsigned_spec in H1.
    rewrite <- H2; symmetry.
    f_equal.
    rewrite <- (Int.repr_unsigned i).
    apply Int.eqm_samerepr; auto.
  + eapply derives_trans; [eassumption |].
    unfold local, lift1; unfold_lift; intro rho; simpl.
    normalize.
    constructor; auto.
  + eapply derives_trans; [eassumption |].
    unfold local, lift1; unfold_lift; intro rho; simpl.
    normalize.
    constructor; auto.
Qed.

Ltac solve_msubst_efield_denote :=
  solve 
  [ repeat first
    [ eapply msubst_efield_denote_cons_array;
      [ reflexivity
      | solve_msubst_eval_expr
      | solve_Int_eqm_unsigned
      | ]
    | apply msubst_efield_denote_cons_struct
    | apply msubst_efield_denote_cons_union
    | apply msubst_efield_denote_nil
    ]
  ].

Inductive field_address_gen {cs: compspecs}: type * list gfield * val -> type * list gfield * val -> Prop :=
| field_address_gen_nil: forall t1 t2 gfs p tgp,
    nested_field_type t2 gfs = t1 ->
    field_address_gen (t2, gfs, p) tgp ->
    field_address_gen (t1, nil, (field_address t2 gfs p)) tgp
| field_address_gen_app: forall t1 t2 gfs1 gfs2 p tgp,
    nested_field_type t2 gfs2 = t1 ->
    field_address_gen (t2, gfs1 ++ gfs2, p) tgp ->
    field_address_gen (t1, gfs1, (field_address t2 gfs2 p)) tgp
| field_address_gen_assu: forall t gfs p1 p2 tgp,
    p1 = p2 ->
    field_address_gen (t, gfs, p2) tgp ->
    field_address_gen (t, gfs, p1) tgp    
| field_address_gen_refl: forall tgp, field_address_gen tgp tgp.

Lemma field_address_gen_fact: forall {cs: compspecs} t1 gfs1 p1 t2 gfs2 p2,
  field_address_gen (t1, gfs1, p1) (t2, gfs2, p2) ->
  field_address t1 gfs1 p1 = field_address t2 gfs2 p2 /\
  nested_field_type t1 gfs1 = nested_field_type t2 gfs2 /\
  (field_compatible t2 gfs2 p2 -> field_compatible t1 gfs1 p1).
Proof.
  intros.
  remember (t1, gfs1, p1) eqn:?H ; remember (t2, gfs2, p2) eqn:?H.
  revert t1 gfs1 p1 t2 gfs2 p2 H0 H1; induction H; intros.
  + subst.
    specialize (IHfield_address_gen _ _ _ _ _ _ eq_refl eq_refl).
    inv H1.
    destruct IHfield_address_gen as [? [? ?]].
    rewrite <- field_address_app.
    simpl.
    rewrite nested_field_type_ind.
    split; [| split]; auto; intros.
    apply field_compatible_app; auto.
  + subst.
    specialize (IHfield_address_gen _ _ _ _ _ _ eq_refl eq_refl).
    inv H1.
    destruct IHfield_address_gen as [? [? ?]].
    rewrite <- field_address_app.
    rewrite nested_field_type_nested_field_type.
    split; [| split]; auto; intros.
    apply field_compatible_app; auto.
  + subst.
    inv H1.
    auto.
  + subst.
    inv H1.
    auto.
Qed.

Ltac field_address_assumption := 
match goal with
 |  H: ?a = field_address _ _ _ |- ?b = _ => constr_eq a b; simple eapply H
end.

Ltac solve_field_address_gen :=
  solve [
    repeat
      first
      [ simple apply field_address_gen_nil; [reflexivity |]
      | simple apply field_address_gen_app; [reflexivity |]
      | simple eapply field_address_gen_assu; [field_address_assumption |]
      | simple apply field_address_gen_refl
      ]
  ].

Inductive find_nth_SEP_preds_rec (pred: mpred -> Prop): nat -> list mpred -> option (nat * mpred) -> Prop :=
| find_nth_SEP_preds_rec_cons_head: forall n R0 R, pred R0 -> find_nth_SEP_preds_rec pred n (R0 :: R) (Some (n, R0))
| find_nth_SEP_preds_rec_cons_tail: forall n R0 R R_res, find_nth_SEP_preds_rec pred (S n) R R_res -> find_nth_SEP_preds_rec pred n (R0 :: R) R_res
| find_nth_SEP_preds_rec_nil: forall n, find_nth_SEP_preds_rec pred n nil None.

Inductive find_nth_SEP_preds (pred: mpred -> Prop): list mpred -> option (nat * mpred) -> Prop :=
| find_nth_SEP_preds_constr: forall R R_res, find_nth_SEP_preds_rec pred 0 R R_res -> find_nth_SEP_preds pred R R_res.

Lemma find_nth_SEP_preds_Some: forall pred R n R0, find_nth_SEP_preds pred R (Some (n, R0)) ->
  nth_error R n = Some R0 /\ pred R0.
Proof.
  intros.
  inv H.
  replace n with (n - 0)%nat by omega.
  assert ((n >= 0)%nat /\ nth_error R (n - 0) = Some R0 /\ pred R0); [| tauto].
  revert H0; generalize 0%nat as m; intros.
  remember (Some (n, R0)) as R_res eqn:?H in H0.
  induction H0.
  + inv H.
    replace (n - n)%nat with 0%nat by omega.
    simpl; auto.
  + apply IHfind_nth_SEP_preds_rec in H.
    destruct H as [? [? ?]].
    replace (n - n0)%nat with (S (n - S n0)) by omega.
    split; [omega |].
    simpl; auto.
  + inv H.
Qed.

Ltac find_nth_SEP_rec tac :=
  first [ simple eapply find_nth_SEP_preds_rec_cons_head; tac
        | simple eapply find_nth_SEP_preds_rec_cons_tail; find_nth_SEP_rec tac
        | simple eapply find_nth_SEP_preds_rec_nil].

Ltac find_nth_SEP tac :=
  eapply find_nth_SEP_preds_constr; find_nth_SEP_rec tac.
(* The reason to use "eapply" instead of "simple eapply" is because "find_nth_SEP" may be buried in definitions. *)

Inductive find_type_contradict_pred {cs: compspecs} (t: type) (p: val): mpred -> Prop :=
| find_type_contradict_pred_data_at: forall sh t0 v0, eqb_type t0 t = false -> find_type_contradict_pred t p (data_at sh t0 v0 p)
| find_type_contradict_pred_data_at_: forall sh t0, eqb_type t0 t = false -> find_type_contradict_pred t p (data_at_ sh t0 p)
| find_type_contradict_pred_field_at: forall sh t0 v0, eqb_type t0 t = false -> find_type_contradict_pred t p (field_at sh t0 nil v0 p)
| find_type_contradict_pred_field_at_: forall sh t0, eqb_type t0 t = false -> find_type_contradict_pred t p (field_at_ sh t0 nil p).

Definition find_type_contradict_preds {cs: compspecs} (t: type) (p: val) :=
  find_nth_SEP_preds (find_type_contradict_pred t p).

Lemma SEP_type_contradict_lemma: forall {cs: compspecs} e R goal Q T1 T2 e_root efs tts lr p_full_from_e p_root_from_e gfs_from_e t_root_from_e p_root_from_hint gfs_from_hint t_root_from_hint
  mm1 mm2,
  local2ptree Q = (T1, T2, nil, nil) ->
  compute_nested_efield e = (e_root, efs, tts, lr) ->
  msubst_eval_lvalue T1 T2 e = Some p_full_from_e ->
  msubst_eval_LR T1 T2 e_root lr = Some p_root_from_e ->
  msubst_efield_denote T1 T2 efs gfs_from_e ->
  compute_root_type (typeof e_root) lr t_root_from_e ->
  field_address_gen (t_root_from_e, gfs_from_e, p_root_from_e) (t_root_from_hint, gfs_from_hint, p_root_from_hint) ->
  find_type_contradict_preds (typeof e) p_full_from_e R mm1 ->
  (gfs_from_hint = nil /\ find_type_contradict_preds t_root_from_hint p_root_from_hint R mm2 \/ mm2 = None) ->
  mm1 = mm2 /\ False ->
  goal.
Proof.
  intros.
  destruct H8 as [? ?].
  exfalso; apply H9; auto.
Qed.

Ltac find_type_contradict_rec :=
  first [ simple eapply find_type_contradict_pred_data_at; reflexivity
        | simple eapply find_type_contradict_pred_data_at_; reflexivity
        | simple eapply find_type_contradict_pred_field_at; reflexivity
        | simple eapply find_type_contradict_pred_field_at_; reflexivity].

Definition unknown_type := Tvoid.

Ltac SEP_type_contradict_msg r e :=
 let t := constr:(typeof e) in
 let t := eval simpl in t in
 let t' := match r with data_at _ ?u _ _ => constr:(u)
                                | data_at_ _ ?u _ => constr:(u)
                                | field_at _ ?u _ _ _ => constr:(u)
                                | field_at_ _ ?u _ _ => constr:(u)
                                | _ => constr:(unknown_type)
             end in
 fail 1000 "Cannot load/store with SEP clause" r "because of type mismatch
Type of expression: " t "
Type in SEP conjunct: " t'.

Ltac SEP_type_contradict LOCAL2PTREE e R :=
  eapply (SEP_type_contradict_lemma e R);
  [ exact LOCAL2PTREE
  | reflexivity
  | solve_msubst_eval_lvalue
  | solve_msubst_eval_LR
  | solve_msubst_efield_denote
  | econstructor
  | solve_field_address_gen
  | find_nth_SEP find_type_contradict_rec
  | first [left; split; [reflexivity | find_nth_SEP find_type_contradict_rec] | right; reflexivity]
  | ];
  match goal with
  | |- Some (_, ?r) = _ /\ False => SEP_type_contradict_msg r e
  | |- _ = Some (_, ?r) /\ False => SEP_type_contradict_msg r e
  | |- _ => idtac
  end;
  fail 0.

Lemma hint_msg_lemma: forall {cs: compspecs} e goal Q T1 T2 e_root efs tts lr p_full_from_e p_root_from_e gfs_from_e t_root_from_e p_root_from_hint gfs_from_hint t_root_from_hint
  t gfs p,
  local2ptree Q = (T1, T2, nil, nil) ->
  compute_nested_efield e = (e_root, efs, tts, lr) ->
  msubst_eval_lvalue T1 T2 e = Some p_full_from_e ->
  msubst_eval_LR T1 T2 e_root lr = Some p_root_from_e ->
  msubst_efield_denote T1 T2 efs gfs_from_e ->
  compute_root_type (typeof e_root) lr t_root_from_e ->
  field_address_gen (t_root_from_e, gfs_from_e, p_root_from_e) (t_root_from_hint, gfs_from_hint, p_root_from_hint) ->
  p_full_from_e = field_address t gfs p /\
  p_root_from_hint = field_address t gfs p /\
  False ->
  goal.
Proof.
  intros.
  destruct H6 as [? [? ?]].
  exfalso; apply H8; auto.
Qed.

Ltac hint_msg LOCAL2PTREE e :=
  eapply (hint_msg_lemma e);
  [ exact LOCAL2PTREE
  | reflexivity
  | solve_msubst_eval_lvalue
  | solve_msubst_eval_LR
  | solve_msubst_efield_denote
  | econstructor
  | solve_field_address_gen
  | ];
  match goal with
  | |- ?eq1 /\ ?eq2 /\ False =>
          first [ constr_eq eq1 eq2;
                   fail 1000 "Please use assert_PROP to prove an equality of the form" eq1
                | fail 1000 "Please use assert_PROP to prove an equality of the form" eq1
                    "or if this does not hold, prove an equality of the form" eq2]
  end.

Section SEMAX_PTREE.

Context {cs: compspecs}.

Lemma semax_PTree_set:
  forall {Espec: OracleKind},
    forall Delta id P Q R T1 T2 (e2: expr) t v,
      local2ptree Q = (T1, T2, nil, nil) ->
      typeof_temp Delta id = Some t ->
      is_neutral_cast (implicit_deref (typeof e2)) t = true ->
      msubst_eval_expr T1 T2 e2 = Some v ->
      ENTAIL Delta, PROPx P (LOCALx Q (SEPx R)) |--
         (tc_expr Delta e2) ->
      semax Delta (|>PROPx P (LOCALx Q (SEPx R)))
        (Sset id e2)
          (normal_ret_assert
            (PROPx P
              (LOCALx (temp id v :: remove_localdef_temp id Q)
                (SEPx R)))).
Proof.
  intros.
  eapply semax_SC_set.
  1: eassumption.
  1: eassumption.
  2: eassumption.
  apply andp_left2.
  erewrite local2ptree_soundness by eassumption.
  apply msubst_eval_expr_eq; auto.
Qed.

Lemma semax_PTree_field_load_no_hint:
  forall {Espec: OracleKind},
    forall n Rn Delta sh id P Q R (e: expr) t
      T1 T2 e_root (efs: list efield) (tts: list type) lr
      t_root_from_e gfs_from_e p_from_e
      (t_root: type) (gfs0 gfs1 gfs: list gfield) (p: val)
      (v : val) (v' : reptype (nested_field_type t_root gfs0)),
      local2ptree Q = (T1, T2, nil, nil) ->
      compute_nested_efield e = (e_root, efs, tts, lr) ->
      typeof_temp Delta id = Some t ->
      is_neutral_cast (typeof e) t = true ->
      type_is_volatile (typeof e) = false ->
      msubst_eval_LR T1 T2 e_root lr = Some p_from_e ->
      msubst_efield_denote T1 T2 efs gfs_from_e ->
      compute_root_type (typeof e_root) lr t_root_from_e ->
      field_address_gen (t_root_from_e, gfs_from_e, p_from_e) (t_root, gfs, p) ->
      find_nth_SEP_preds (fun Rn => Rn = field_at sh t_root gfs0 v' p /\ gfs = gfs1 ++ gfs0) R (Some (n, Rn)) ->
      readable_share sh ->
      JMeq (proj_reptype (nested_field_type t_root gfs0) gfs1 v') v ->
      ENTAIL Delta, PROPx P (LOCALx Q (SEPx R)) |--
        !! (legal_nested_field (nested_field_type t_root gfs0) gfs1) ->
      ENTAIL Delta, PROPx P (LOCALx Q (SEPx R)) |--
         (tc_LR Delta e_root lr) &&
        local `(tc_val (typeof e) v) &&
         (tc_efield Delta efs) ->
      semax Delta (|>PROPx P (LOCALx Q (SEPx R)))
        (Sset id e)
          (normal_ret_assert
            (PROPx P
              (LOCALx (temp id v :: remove_localdef_temp id Q)
                (SEPx R)))).
Proof.
  intros ? ? ? ? ? ? ? ? ? ? ?
         ? ? ? ? ? ?
         ? ? ?
         ? ? ? ? ?
         ? ?
         LOCAL2PTREE COMPUTE_NESTED_EFIELD ? ? ? EVAL_ROOT EVAL_EFIELD ROOT_TYPE
         FIELD_ADD_GEN NTH SH JMEQ LEGAL_NESTED_FIELD TC.
  pose proof is_neutral_cast_by_value _ _ H0 as BY_VALUE.
  assert_PROP (nested_efield e_root efs tts = e /\
               LR_of_type t_root_from_e = lr /\
               legal_nested_efield t_root_from_e e_root gfs_from_e tts lr = true /\
               nested_field_type t_root_from_e gfs_from_e = typeof e).
  Focus 1. {
    erewrite (local2ptree_soundness P Q R) by eauto.
    simpl app.
    apply (msubst_efield_denote_eq P _ _ nil R)  in EVAL_EFIELD.
    eapply derives_trans; [apply andp_left2, EVAL_EFIELD |].
    intro rho; simpl; unfold local, lift1; unfold_lift.
    apply prop_derives; intros.
    pose proof compute_nested_efield_lemma _ rho BY_VALUE.
    rewrite COMPUTE_NESTED_EFIELD in H3; apply H3; auto.
  } Unfocus.
  apply find_nth_SEP_preds_Some in NTH.
  destruct NTH as [NTH [? GFS]]; subst Rn.
  destruct H2 as [NESTED_EFIELD [LR [LEGAL_NESTED_EFIELD TYPEOF]]].
  rewrite <- TYPEOF in BY_VALUE.
  assert_PROP (field_compatible t_root gfs0 p).
  Focus 1. {
    rewrite <- (corable_sepcon_TT (prop _)) by auto.
    eapply nth_error_SEP_sepcon_TT'; [| eassumption].
    apply andp_left2.
    apply andp_left2.
    apply andp_left2.
    rewrite field_at_compatible'.
    go_lowerx.
    normalize.
  } Unfocus.
  rename H2 into FIELD_COMPATIBLE.
  assert_PROP (legal_nested_field (nested_field_type t_root gfs0) gfs1); auto.
  clear LEGAL_NESTED_FIELD; rename H2 into LEGAL_NESTED_FIELD.
  eapply field_compatible_app_inv' in FIELD_COMPATIBLE; [| exact LEGAL_NESTED_FIELD].
  rewrite <- GFS in FIELD_COMPATIBLE.
  rewrite <- NESTED_EFIELD.
  apply field_address_gen_fact in FIELD_ADD_GEN.
  destruct FIELD_ADD_GEN as [FIELD_ADD_EQ [TYPE_EQ FIELD_COMPATIBLE_E]].
  specialize (FIELD_COMPATIBLE_E FIELD_COMPATIBLE).
  pose proof nested_efield_facts Delta _ _ efs _ _ _ _ FIELD_COMPATIBLE_E LR LEGAL_NESTED_EFIELD BY_VALUE as DERIVES.
  apply (derives_trans (local (tc_environ Delta) && PROPx P (LOCALx Q (SEPx R)))) in DERIVES.
  Focus 2. {
    rewrite (andp_comm _ (local (efield_denote _ _))), <- !andp_assoc.
    rewrite (add_andp _ _ TC).
    rewrite LR.
    apply andp_right; [| solve_andp].
    apply andp_right; [| solve_andp].
    apply andp_right; [| solve_andp].
    apply andp_left1.
    erewrite (local2ptree_soundness P Q R) by eauto.
    apply andp_left2.
    simpl app.
    apply andp_right.
    + apply (msubst_efield_denote_eq P _ _ nil R) in EVAL_EFIELD; auto.
    + apply (msubst_eval_LR_eq P _ _ nil R) in EVAL_ROOT; auto.
  } Unfocus.
  eapply semax_SC_field_load.
  1: rewrite NESTED_EFIELD, <- TYPEOF, TYPE_EQ; reflexivity.
  1: eassumption.
  1: rewrite <- TYPE_EQ, TYPEOF; eassumption.
  1: rewrite <- TYPE_EQ, TYPEOF; eassumption.
  2: eassumption.
  2: eassumption.
  2: eassumption.
  2: eassumption.
  + rewrite <- FIELD_ADD_EQ.
    eapply derives_trans; [exact DERIVES | solve_andp].
  + apply andp_right.
    - eapply derives_trans; [exact DERIVES | solve_andp].
    - rewrite <- TYPE_EQ, TYPEOF.
      rewrite (add_andp _ _ TC); solve_andp.
Qed.

Lemma semax_PTree_field_load_with_hint:
  forall {Espec: OracleKind},
    forall n Rn Delta sh id P Q R (e: expr) t
      T1 T2 p_from_e
      (t_root: type) (gfs0 gfs1 gfs: list gfield) (p: val)
      (v_val : val) (v_reptype : reptype (nested_field_type t_root gfs0)),
      local2ptree Q = (T1, T2, nil, nil) ->
      typeof_temp Delta id = Some t ->
      is_neutral_cast (typeof e) t = true ->
      type_is_volatile (typeof e) = false ->
      msubst_eval_lvalue T1 T2 e = Some p_from_e ->
      p_from_e = field_address t_root gfs p ->
      typeof e = nested_field_type t_root gfs ->
      find_nth_SEP_preds (fun Rn => Rn = field_at sh t_root gfs0 v_reptype p /\ gfs = gfs1 ++ gfs0) R (Some (n, Rn)) ->
      readable_share sh ->
      JMeq (proj_reptype (nested_field_type t_root gfs0) gfs1 v_reptype) v_val ->
      ENTAIL Delta, PROPx P (LOCALx Q (SEPx R)) |--
        (tc_lvalue Delta e) && local (`(tc_val (typeof e) v_val)) ->
      @semax cs Espec Delta (|> PROPx P (LOCALx Q (SEPx R)))
        (Sset id e)
        (normal_ret_assert
          (PROPx P
            (LOCALx (temp id v_val :: remove_localdef_temp id Q)
              (SEPx R)))).
Proof.
  intros ? ? ? ? ? ? ? ? ? ?
         ? ? ? ?
         ? ? ? ? ?
         ? ?
         LOCAL2PTREE ? ? ? EVAL_L FIELD_ADD TYPE_EQ NTH SH JMEQ TC.
  apply find_nth_SEP_preds_Some in NTH.
  destruct NTH as [NTH [? GFS]]; subst Rn.
  eapply semax_SC_field_load.
  1: eassumption.
  1: eassumption.
  1: rewrite <- TYPE_EQ; eassumption.
  1: rewrite <- TYPE_EQ; eassumption.
  2: eassumption.
  2: eassumption.
  2: eassumption.
  2: eassumption.
  2: rewrite <- TYPE_EQ; eassumption.
  rewrite <- FIELD_ADD.
  erewrite (local2ptree_soundness P Q R) by eassumption.
  simpl app.
  apply andp_left2. apply msubst_eval_lvalue_eq; auto.
Qed.

Lemma semax_PTree_field_cast_load_no_hint:
  forall {Espec: OracleKind},
    forall n Rn Delta sh id P Q R (e: expr) t
      T1 T2 e_root (efs: list efield) (tts: list type) lr
      t_root_from_e gfs_from_e p_from_e
      (t_root: type) (gfs0 gfs1 gfs: list gfield) (p: val)
      (v : val) (v' : reptype (nested_field_type t_root gfs0)),
      local2ptree Q = (T1, T2, nil, nil) ->
      compute_nested_efield e = (e_root, efs, tts, lr) ->
      typeof_temp Delta id = Some t ->
      type_is_by_value (typeof e) = true ->
      type_is_volatile (typeof e) = false ->
      cast_pointer_to_bool (typeof e) t = false ->
      msubst_eval_LR T1 T2 e_root lr = Some p_from_e ->
      msubst_efield_denote T1 T2 efs gfs_from_e ->
      compute_root_type (typeof e_root) lr t_root_from_e ->
      field_address_gen (t_root_from_e, gfs_from_e, p_from_e) (t_root, gfs, p) ->
      find_nth_SEP_preds (fun Rn => Rn = field_at sh t_root gfs0 v' p /\ gfs = gfs1 ++ gfs0) R (Some (n, Rn)) ->
      readable_share sh ->
      JMeq (proj_reptype (nested_field_type t_root gfs0) gfs1 v') v ->
      ENTAIL Delta, PROPx P (LOCALx Q (SEPx R)) |--
        !! (legal_nested_field (nested_field_type t_root gfs0) gfs1) ->
      ENTAIL Delta, PROPx P (LOCALx Q (SEPx R)) |--
         (tc_LR Delta e_root lr) &&
        local `(tc_val t (eval_cast (typeof e) t v)) &&
         (tc_efield Delta efs) ->
      semax Delta (|>PROPx P (LOCALx Q (SEPx R)))
        (Sset id (Ecast e t))
          (normal_ret_assert
            (PROPx P
              (LOCALx (temp id (eval_cast (typeof e) t v) :: remove_localdef_temp id Q)
                (SEPx R)))).
Proof.
  intros ? ? ? ? ? ? ? ? ? ? ?
         ? ? ? ? ? ?
         ? ? ?
         ? ? ? ? ?
         ? ?
         LOCAL2PTREE COMPUTE_NESTED_EFIELD ? BY_VALUE ? ? EVAL_ROOT EVAL_EFIELD ROOT_TYPE
         FIELD_ADD_GEN NTH SH JMEQ LEGAL_NESTED_FIELD TC.
  assert_PROP (nested_efield e_root efs tts = e /\
               LR_of_type t_root_from_e = lr /\
               legal_nested_efield t_root_from_e e_root gfs_from_e tts lr = true /\
               nested_field_type t_root_from_e gfs_from_e = typeof e).
  Focus 1. {
    erewrite (local2ptree_soundness P Q R) by eauto.
    simpl app.
    apply (msubst_efield_denote_eq P _ _ nil R)  in EVAL_EFIELD.
    eapply derives_trans; [apply andp_left2, EVAL_EFIELD |].
    intro rho; simpl; unfold local, lift1; unfold_lift.
    apply prop_derives; intros.
    pose proof compute_nested_efield_lemma _ rho BY_VALUE.
    rewrite COMPUTE_NESTED_EFIELD in H3; apply H3; auto.
  } Unfocus.
  apply find_nth_SEP_preds_Some in NTH.
  destruct NTH as [NTH [? GFS]]; subst Rn.
  destruct H2 as [NESTED_EFIELD [LR [LEGAL_NESTED_EFIELD TYPEOF]]].
  rewrite <- TYPEOF in BY_VALUE.
  assert_PROP (field_compatible t_root gfs0 p).
  Focus 1. {
    rewrite <- (corable_sepcon_TT (prop _)) by auto.
    eapply nth_error_SEP_sepcon_TT'; [| eassumption].
    apply andp_left2.
    apply andp_left2.
    apply andp_left2.
    rewrite field_at_compatible'.
    go_lowerx.
    normalize.
  } Unfocus.
  rename H2 into FIELD_COMPATIBLE.
  assert_PROP (legal_nested_field (nested_field_type t_root gfs0) gfs1); auto.
  clear LEGAL_NESTED_FIELD; rename H2 into LEGAL_NESTED_FIELD.
  eapply field_compatible_app_inv' in FIELD_COMPATIBLE; [| exact LEGAL_NESTED_FIELD].
  rewrite <- GFS in FIELD_COMPATIBLE.
  rewrite <- NESTED_EFIELD.
  apply field_address_gen_fact in FIELD_ADD_GEN.
  destruct FIELD_ADD_GEN as [FIELD_ADD_EQ [TYPE_EQ FIELD_COMPATIBLE_E]].
  specialize (FIELD_COMPATIBLE_E FIELD_COMPATIBLE).
  pose proof nested_efield_facts Delta _ _ efs _ _ _ _ FIELD_COMPATIBLE_E LR LEGAL_NESTED_EFIELD BY_VALUE as DERIVES.
  apply (derives_trans (local (tc_environ Delta) && PROPx P (LOCALx Q (SEPx R)))) in DERIVES.
  Focus 2. {
    rewrite (andp_comm _ (local (efield_denote _ _))), <- !andp_assoc.
    rewrite (add_andp _ _ TC).
    rewrite LR.
    apply andp_right; [| solve_andp].
    apply andp_right; [| solve_andp].
    apply andp_right; [| solve_andp].
    apply andp_left1.
    erewrite (local2ptree_soundness P Q R) by eauto.
    apply andp_left2.
    simpl app.
    apply andp_right.
    + apply (msubst_efield_denote_eq P _ _ nil R) in EVAL_EFIELD; auto.
    + apply (msubst_eval_LR_eq P _ _ nil R) in EVAL_ROOT; auto.
  } Unfocus.
  rewrite NESTED_EFIELD. rewrite <- TYPEOF, TYPE_EQ.
  eapply semax_SC_field_cast_load.
  1: rewrite <- TYPEOF, TYPE_EQ; reflexivity.
  1: eassumption.
  1: rewrite <- TYPE_EQ; eassumption.
  1: rewrite <- TYPE_EQ, TYPEOF; eassumption.
  1: rewrite <- TYPE_EQ, TYPEOF; eassumption.
  2: eassumption.
  2: eassumption.
  2: eassumption.
  2: eassumption.
  + rewrite <- FIELD_ADD_EQ.
    eapply derives_trans; [exact DERIVES | rewrite NESTED_EFIELD; solve_andp].
  + apply andp_right.
    - eapply derives_trans; [exact DERIVES | rewrite NESTED_EFIELD; solve_andp].
    - rewrite <- TYPE_EQ, TYPEOF.
      rewrite (add_andp _ _ TC); solve_andp.
Qed.

Lemma semax_PTree_field_cast_load_with_hint:
  forall {Espec: OracleKind},
    forall n Rn Delta sh id P Q R (e: expr) t
      T1 T2 p_from_e
      (t_root: type) (gfs0 gfs1 gfs: list gfield) (p: val)
      (v_val : val) (v_reptype : reptype (nested_field_type t_root gfs0)),
      local2ptree Q = (T1, T2, nil, nil) ->
      typeof_temp Delta id = Some t ->
      type_is_by_value (typeof e) = true ->
      type_is_volatile (typeof e) = false ->
      cast_pointer_to_bool (typeof e) t = false ->
      msubst_eval_lvalue T1 T2 e = Some p_from_e ->
      p_from_e = field_address t_root gfs p ->
      typeof e = nested_field_type t_root gfs ->
      find_nth_SEP_preds (fun Rn => Rn = field_at sh t_root gfs0 v_reptype p /\ gfs = gfs1 ++ gfs0) R (Some (n, Rn)) ->
      readable_share sh ->
      JMeq (proj_reptype (nested_field_type t_root gfs0) gfs1 v_reptype) v_val ->
      ENTAIL Delta, PROPx P (LOCALx Q (SEPx R)) |--
        (tc_lvalue Delta e) && local (`(tc_val t (eval_cast (typeof e) t v_val))) ->
      @semax cs Espec Delta (|> PROPx P (LOCALx Q (SEPx R)))
        (Sset id (Ecast e t))
        (normal_ret_assert
          (PROPx P
            (LOCALx (temp id (eval_cast (typeof e) t v_val) :: remove_localdef_temp id Q)
              (SEPx R)))).
Proof.
  intros ? ? ? ? ? ? ? ? ? ?
         ? ? ? ?
         ? ? ? ? ?
         ? ?
         LOCAL2PTREE ? ? ? ? EVAL_L FIELD_ADD TYPE_EQ NTH SH JMEQ TC.
  apply find_nth_SEP_preds_Some in NTH.
  destruct NTH as [NTH [? GFS]]; subst Rn.
  rewrite TYPE_EQ.
  eapply semax_SC_field_cast_load.
  1: eassumption.
  1: eassumption.
  1: rewrite <- TYPE_EQ; eassumption.
  1: rewrite <- TYPE_EQ; eassumption.
  1: rewrite <- TYPE_EQ; eassumption.
  2: eassumption.
  2: eassumption.
  2: eassumption.
  2: eassumption.
  2: rewrite <- TYPE_EQ; eassumption.
  rewrite <- FIELD_ADD.
  erewrite (local2ptree_soundness P Q R) by eassumption.
  simpl app.
  apply andp_left2. apply msubst_eval_lvalue_eq; auto.
Qed.

Lemma semax_PTree_field_store_no_hint:
  forall {Espec: OracleKind},
    forall n Rn Delta sh P Q R (e1 e2 : expr)
      T1 T2 e_root (efs: list efield) (tts: list type) lr
      t_root_from_e gfs_from_e p_from_e
      (t_root: type) (gfs0 gfs1 gfs: list gfield) (p: val) 
      (v0: reptype (nested_field_type (nested_field_type t_root gfs0) gfs1))
      (v0_val: val) Rv (v v_new: reptype (nested_field_type t_root gfs0)),
      local2ptree Q = (T1, T2, nil, nil) ->
      compute_nested_efield e1 = (e_root, efs, tts, lr) ->
      type_is_by_value (typeof e1) = true ->
      type_is_volatile (typeof e1) = false ->
      msubst_eval_expr T1 T2 (Ecast e2 (typeof e1)) = Some v0_val ->
      msubst_eval_LR T1 T2 e_root lr = Some p_from_e ->
      msubst_efield_denote T1 T2 efs gfs_from_e ->
      compute_root_type (typeof e_root) lr t_root_from_e ->
      field_address_gen (t_root_from_e, gfs_from_e, p_from_e) (t_root, gfs, p) ->
      find_nth_SEP_preds (fun Rn => (Rn = Rv v /\ (Rv = fun v => field_at sh t_root gfs0 v p)) /\ gfs = gfs1 ++ gfs0) R (Some (n, Rn)) ->
      writable_share sh ->
      JMeq v0_val v0 ->
      data_equal (upd_reptype (nested_field_type t_root gfs0) gfs1 v v0) v_new ->
      ENTAIL Delta, PROPx P (LOCALx Q (SEPx R)) |--
        !! (legal_nested_field (nested_field_type t_root gfs0) gfs1) ->
      ENTAIL Delta, PROPx P (LOCALx Q (SEPx R)) |--
         (tc_LR Delta e_root lr) &&
         (tc_expr Delta (Ecast e2 (typeof e1))) &&
         (tc_efield Delta efs) ->
      semax Delta (|>PROPx P (LOCALx Q (SEPx R)))
        (Sassign e1 e2)
          (normal_ret_assert
            (PROPx P
              (LOCALx Q
                (SEPx
                  (replace_nth n R (Rv v_new)))))).
Proof.
  intros ? ? ? ? ? ? ? ? ? ?
         ? ? ? ? ? ?
         ? ? ? ?
         ? ? ? ? ?
         ? ? ? ?
         LOCAL2PTREE COMPUTE_NESTED_EFIELD BY_VALUE ? EVAL_R EVAL_ROOT EVAL_EFIELD ROOT_TYPE
         FIELD_ADD_GEN NTH SH JMEQ DATA_EQ LEGAL_NESTED_FIELD TC.
  assert_PROP (nested_efield e_root efs tts = e1 /\
               LR_of_type t_root_from_e = lr /\
               legal_nested_efield t_root_from_e e_root gfs_from_e tts lr = true /\
               nested_field_type t_root_from_e gfs_from_e = typeof e1).
  Focus 1. {
    erewrite (local2ptree_soundness P Q R) by eauto.
    simpl app.
    apply (msubst_efield_denote_eq P _ _ nil R)  in EVAL_EFIELD.
    eapply derives_trans; [apply andp_left2, EVAL_EFIELD |].
    intro rho; simpl; unfold local, lift1; unfold_lift.
    apply prop_derives; intros.
    pose proof compute_nested_efield_lemma _ rho BY_VALUE.
    rewrite COMPUTE_NESTED_EFIELD in H1; apply H1; auto.
  } Unfocus.
  apply find_nth_SEP_preds_Some in NTH.
  destruct NTH as [NTH [[? ?] GFS]]; subst Rn Rv.
  destruct H0 as [NESTED_EFIELD [LR [LEGAL_NESTED_EFIELD TYPEOF]]].
  rewrite <- TYPEOF in BY_VALUE.
  assert_PROP (field_compatible t_root gfs0 p).
  Focus 1. {
    rewrite <- (corable_sepcon_TT (prop _)) by auto.
    eapply nth_error_SEP_sepcon_TT'; [| eassumption].
    apply andp_left2.
    apply andp_left2.
    apply andp_left2.
    rewrite field_at_compatible'.
    go_lowerx.
    normalize.
  } Unfocus.
  rename H0 into FIELD_COMPATIBLE.
  assert_PROP (legal_nested_field (nested_field_type t_root gfs0) gfs1); auto.
  clear LEGAL_NESTED_FIELD; rename H0 into LEGAL_NESTED_FIELD.
  eapply field_compatible_app_inv' in FIELD_COMPATIBLE; [| exact LEGAL_NESTED_FIELD].
  rewrite <- GFS in FIELD_COMPATIBLE.
  rewrite <- NESTED_EFIELD.
  apply field_address_gen_fact in FIELD_ADD_GEN.
  destruct FIELD_ADD_GEN as [FIELD_ADD_EQ [TYPE_EQ FIELD_COMPATIBLE_E]].
  specialize (FIELD_COMPATIBLE_E FIELD_COMPATIBLE).
  pose proof nested_efield_facts Delta _ _ efs _ _ _ _ FIELD_COMPATIBLE_E LR LEGAL_NESTED_EFIELD BY_VALUE as DERIVES.
  apply (derives_trans (local (tc_environ Delta) && PROPx P (LOCALx Q (SEPx R)))) in DERIVES.
  Focus 2. {
    rewrite (andp_comm _ (local (efield_denote _ _))), <- !andp_assoc.
    rewrite (add_andp _ _ TC).
    rewrite LR.
    apply andp_right; [| solve_andp].
    apply andp_right; [| solve_andp].
    apply andp_right; [| solve_andp].
    apply andp_left1.
    erewrite (local2ptree_soundness P Q R) by eauto.
    apply andp_left2.
    simpl app.
    apply andp_right.
    + apply (msubst_efield_denote_eq P _ _ nil R) in EVAL_EFIELD; auto.
    + apply (msubst_eval_LR_eq P _ _ nil R) in EVAL_ROOT; auto.
  } Unfocus.
  rewrite NESTED_EFIELD.
  eapply semax_SC_field_store.
  1: rewrite <- TYPEOF, TYPE_EQ; reflexivity.
  1: rewrite <- TYPE_EQ; eassumption.
  1: rewrite <- TYPE_EQ, TYPEOF; eassumption.
  1: eassumption.
  1: eassumption.
  3: eassumption.
  3: eapply JMeq_sym; eassumption.
  3: eassumption.
  + rewrite <- FIELD_ADD_EQ.
    eapply derives_trans; [exact DERIVES | rewrite NESTED_EFIELD; solve_andp].
  + rewrite <- TYPE_EQ, TYPEOF.
    apply andp_left2.
    erewrite local2ptree_soundness by eauto.
    apply msubst_eval_expr_eq; eauto.
  + rewrite (add_andp _ _ DERIVES), (add_andp _ _ TC).
    rewrite <- TYPE_EQ, TYPEOF, NESTED_EFIELD.
    solve_andp.
Qed.

Lemma semax_PTree_field_store_with_hint:
  forall {Espec: OracleKind},
    forall n Rn Delta sh P Q R (e1 e2 : expr)
      T1 T2 p_from_e
      (t_root: type) (gfs0 gfs1 gfs: list gfield) (p: val) 
      (v0: reptype (nested_field_type (nested_field_type t_root gfs0) gfs1))
      (v0_val: val) Rv (v v_new: reptype (nested_field_type t_root gfs0)),
      local2ptree Q = (T1, T2, nil, nil) ->
      type_is_by_value (typeof e1) = true ->
      type_is_volatile (typeof e1) = false ->
      msubst_eval_expr T1 T2 (Ecast e2 (typeof e1)) = Some v0_val ->
      msubst_eval_lvalue T1 T2 e1 = Some p_from_e ->
      p_from_e = field_address t_root gfs p ->
      typeof e1 = nested_field_type t_root gfs ->
      find_nth_SEP_preds (fun Rn => (Rn = Rv v /\ (Rv = fun v => field_at sh t_root gfs0 v p)) /\ gfs = gfs1 ++ gfs0) R (Some (n, Rn)) ->
      writable_share sh ->
      JMeq v0_val v0 ->
      data_equal (upd_reptype (nested_field_type t_root gfs0) gfs1 v v0) v_new ->
      ENTAIL Delta, PROPx P (LOCALx Q (SEPx R)) |--
         (tc_lvalue Delta e1) &&
         (tc_expr Delta (Ecast e2 (typeof e1))) ->
      semax Delta (|>PROPx P (LOCALx Q (SEPx R)))
        (Sassign e1 e2)
          (normal_ret_assert
            (PROPx P
              (LOCALx Q
                (SEPx
                  (replace_nth n R
                    (field_at sh t_root gfs0 v_new p)))))).
Proof.
  intros ? ? ? ? ? ? ? ? ? ?
         ? ? ? ?
         ? ? ? ? ? ?
         ? ? ?
         LOCAL2PTREE ? ? EVAL_R EVAL_L FIELD_ADD TYPE_EQ NTH SH JMEQ DATA_EQ TC.
  apply find_nth_SEP_preds_Some in NTH.
  destruct NTH as [NTH [[? ?] GFS]]; subst Rn Rv.
  eapply semax_SC_field_store.
  1: eassumption.
  1: rewrite <- TYPE_EQ; eassumption.
  1: rewrite <- TYPE_EQ; eassumption.
  1: eassumption.
  1: eassumption.
  3: eassumption.
  3: eapply JMeq_sym; eassumption.
  3: eassumption.
  3: rewrite <- TYPE_EQ; auto.
  + rewrite <- FIELD_ADD.
    erewrite (local2ptree_soundness P Q R) by eassumption.
    simpl app.
    apply andp_left2. apply msubst_eval_lvalue_eq; auto.
  + rewrite <- TYPE_EQ.
    erewrite (local2ptree_soundness P Q R) by eassumption.
    simpl app.
    apply andp_left2. apply msubst_eval_expr_eq; auto.
Qed.

Definition proj_val t_root gfs v :=
   repinject (nested_field_type t_root gfs) (proj_reptype t_root gfs v).

Definition upd_val t_root gfs v v0 :=
   upd_reptype t_root gfs v (valinject (nested_field_type t_root gfs) v0).

End SEMAX_PTREE.

Ltac SEP_field_at_unify' gfs :=
  match goal with
  | |- field_at ?shl ?tl ?gfsl ?vl ?pl = field_at ?shr ?tr ?gfsr ?vr ?pr =>
      unify tl tr;
      unify (skipn (length gfs - length gfsl) gfs) gfsl;
      unify gfsl gfsr;
      unify shl shr;
      unify vl vr;
      generalize vl; intro;
      rewrite <- ?field_at_offset_zero; reflexivity
  end.

Ltac SEP_field_at_unify gfs :=
  match goal with
  | |- data_at _ _ _ _ = _ =>
      unfold data_at; SEP_field_at_unify' gfs
  | |- data_at_ _ _ _ = _ =>
      unfold data_at_, field_at_; SEP_field_at_unify' gfs
  | |- field_at _ _ _ _ _ = _ =>
      SEP_field_at_unify' gfs
  | |- field_at_ _ _ _ _ = _ =>
      unfold field_at_; SEP_field_at_unify' gfs
  end.

Ltac SEP_field_at_strong_unify' gfs :=
  match goal with
  | |- @field_at ?cs ?shl ?tl ?gfsl ?vl ?pl = ?Rv ?vr /\ (_ = fun v => field_at ?shr ?tr ?gfsr v ?pr) =>
      unify tl tr;
      unify (skipn (length gfs - length gfsl) gfs) gfsl;
      unify gfsl gfsr;
      unify shl shr;
      unify vl vr;
      split;
      [ match type of vl with
        | ?tv1 => unify Rv (fun v: tv1 => @field_at cs shl tl gfsl v pl)
        end; reflexivity
      | extensionality;
        rewrite <- ?field_at_offset_zero; reflexivity]
  | |- @data_at ?cs ?shl ?tl ?vl ?pl = ?Rv ?vr /\ (_ = fun v => field_at ?shr ?tr ?gfsr v ?pr) =>
      unify tl tr;
      unify gfsr (@nil gfield);
      unify shl shr;
      unify vl vr;
      split;
      [ match type of vl with
        | ?tv1 => unify Rv (fun v: tv1 => @data_at cs shl tl v pl)
        end; reflexivity
      | extensionality;
        unfold data_at;
        rewrite <- ?field_at_offset_zero; reflexivity]
  end.

Ltac SEP_field_at_strong_unify gfs :=
  match goal with
  | |- data_at_ ?sh ?t ?p = _ /\ _ =>
      change (data_at_ sh t p) with (data_at sh t (default_val t) p);
      SEP_field_at_strong_unify' gfs
  | |- field_at_ _ _ _ _ = _ /\ _ =>
      unfold field_at_; SEP_field_at_strong_unify' gfs
  | _ => SEP_field_at_strong_unify' gfs
  end.

(* simplifies a list expression into [e1; e2; ...] form without simplifying its elements *)
Ltac eval_list l :=
  let l' := eval hnf in l in lazymatch l' with
  | ?h :: ?tl => let tl' := eval_list tl in constr:(h :: tl')
  | (@nil ?T) => constr:(@nil T)
  end.

Ltac prove_gfs_suffix gfs :=
  match goal with
  | |- _ = ?gfs1 ++ ?gfs0 =>
       let len := fresh "len" in
       let gfs1' := eval_list (firstn ((length gfs - length gfs0)%nat) gfs) in
       unify gfs1 gfs1';
       reflexivity
  end.

Ltac test_field_at_in_SEP :=
cbv beta;
match goal with
| |- ?A /\ ?gfs = _ ++ _ =>
  split; [ match A with
           | _ /\ _ => SEP_field_at_strong_unify gfs
           | _ => SEP_field_at_unify gfs
           end
         | prove_gfs_suffix gfs]
end.

Ltac search_field_at_in_SEP := find_nth_SEP test_field_at_in_SEP.

Lemma quick_derives_right:
  forall P Q : environ -> mpred,
   TT |-- Q -> P |-- Q.
Proof.
intros. eapply derives_trans; try eassumption; auto.
Qed.

Ltac quick_typecheck3 :=
 clear;
 repeat match goal with
 | H := _ |- _ => clear H
 | H : _ |- _ => clear H
 end;
 apply quick_derives_right; clear; go_lowerx; intros;
 clear; repeat apply andp_right; auto; fail.

Ltac default_entailer_for_load_store :=
  repeat match goal with H := _ |- _ => clear H end;
  try quick_typecheck3;
  unfold tc_efield, tc_LR, tc_LR_strong; simpl typeof;
  try solve [entailer!].

Ltac entailer_for_load_tac := default_entailer_for_load_store.

Ltac entailer_for_store_tac := default_entailer_for_load_store.

Ltac load_tac_with_hint LOCAL2PTREE :=
  eapply semax_PTree_field_load_with_hint;
  [ exact LOCAL2PTREE
  | reflexivity
  | reflexivity
  | reflexivity
  | solve_msubst_eval_lvalue
  | eassumption (* This line can fail. If it does not, the following should not fail. *)
  | (reflexivity                            || fail 1000 "unexpected failure in load_tac_with_hint."
                                                         "The hint does not type match")
  | (search_field_at_in_SEP                 || fail 1000 "unexpected failure in load_tac_with_hint."
                                                         "Required field_at does not exists in SEP")
  | (auto                                   || fail 1000 "unexpected failure in load_tac_with_hint."
                                                         "Cannot prove readable_share")
  | first [solve_load_rule_evaluation        | fail 1000 "unexpected failure in load_tac_with_hint."
                                                         "unexpected failure in generating loaded value"]
  | first [entailer_for_load_tac             | fail 1000 "unexpected failure in load_tac_with_hint."
                                                         "unexpected failure in entailer_for_load_tac"]
  ].

Ltac load_tac_no_hint LOCAL2PTREE :=
  eapply semax_PTree_field_load_no_hint;
  [ exact LOCAL2PTREE
  | reflexivity (* compute_nested_efield *)
  | reflexivity
  | reflexivity
  | reflexivity
  | solve_msubst_eval_LR
  | solve_msubst_efield_denote
  | econstructor
  | solve_field_address_gen
  | search_field_at_in_SEP (* This line can fail. If it does not, the following should not fail. *)
  | (auto                                   || fail 1000 "unexpected failure in load_tac_no_hint."
                                                         "Cannot prove readable_share")
  | first [solve_load_rule_evaluation        | fail 1000 "unexpected failure in load_tac_no_hint."
                                                         "unexpected failure in generating loaded value"]
  | first [solve_legal_nested_field_in_entailment
                                             | fail 1000 "unexpected failure in load_tac_no_hint."
                                                         "unexpected failure in solve_legal_nested_field_in_entailment"]
  | first [entailer_for_load_tac             | fail 1000 "unexpected failure in load_tac_no_hint."
                                                         "unexpected failure in entailer_for_load_tac"]
  ].

Ltac load_tac :=
  match goal with
  | |- semax ?Delta (|> (PROPx ?P (LOCALx ?Q (SEPx ?R)))) (Sset _ ?e) _ =>
    let T1 := fresh "T1" in evar (T1: PTree.t val);
    let T2 := fresh "T2" in evar (T2: PTree.t vardesc);
    let LOCAL2PTREE := fresh "LOCAL2PTREE" in
    assert (local2ptree Q = (T1, T2, nil, nil)) as LOCAL2PTREE;
    [subst T1 T2; prove_local2ptree |];
    first [ load_tac_with_hint LOCAL2PTREE | load_tac_no_hint LOCAL2PTREE | SEP_type_contradict LOCAL2PTREE e R | hint_msg LOCAL2PTREE e];
    clear T1 T2 LOCAL2PTREE
  end.

Ltac cast_load_tac_with_hint LOCAL2PTREE :=
  eapply semax_PTree_field_cast_load_with_hint;
  [ exact LOCAL2PTREE
  | reflexivity
  | reflexivity
  | reflexivity
  | reflexivity
  | solve_msubst_eval_lvalue
  | eassumption (* This line can fail. If it does not, the following should not fail. *)
  | (reflexivity                            || fail 1000 "unexpected failure in cast_load_tac_with_hint."
                                                         "The hint does not type match")
  | (search_field_at_in_SEP                 || fail 1000 "unexpected failure in cast_load_tac_with_hint."
                                                         "Required field_at does not exists in SEP")
  | (auto                                   || fail 1000 "unexpected failure in cast_load_tac_with_hint."
                                                         "Cannot prove readable_share")
  | first [solve_load_rule_evaluation        | fail 1000 "unexpected failure in cast_load_tac_with_hint."
                                                         "unexpected failure in generating loaded value"]
  | first [entailer_for_load_tac             | fail 1000 "unexpected failure in cast_load_tac_with_hint."
                                                         "unexpected failure in entailer_for_load_tac"]
  ].

Ltac cast_load_tac_no_hint LOCAL2PTREE :=
  eapply semax_PTree_field_cast_load_no_hint;
  [ exact LOCAL2PTREE
  | reflexivity (* compute_nested_efield *)
  | reflexivity
  | reflexivity
  | reflexivity
  | reflexivity
  | solve_msubst_eval_LR
  | solve_msubst_efield_denote
  | econstructor
  | solve_field_address_gen
  | search_field_at_in_SEP (* This line can fail. If it does not, the following should not fail. *)
  | (auto                                   || fail 1000 "unexpected failure in cast_load_tac_no_hint."
                                                         "Cannot prove readable_share")
  | first [solve_load_rule_evaluation        | fail 1000 "unexpected failure in cast_load_tac_no_hint."
                                                         "unexpected failure in generating loaded value"]
  | first [solve_legal_nested_field_in_entailment
                                             | fail 1000 "unexpected failure in cast_load_tac_no_hint."
                                                         "unexpected failure in solve_legal_nested_field_in_entailment"]
  | first [entailer_for_load_tac             | fail 1000 "unexpected failure in cast_load_tac_no_hint."
                                                         "unexpected failure in entailer_for_load_tac"]
  ].

Ltac cast_load_tac :=
  match goal with
  | |- semax ?Delta (|> (PROPx ?P (LOCALx ?Q (SEPx ?R)))) (Sset _ (Ecast ?e _)) _ =>
    let T1 := fresh "T1" in evar (T1: PTree.t val);
    let T2 := fresh "T2" in evar (T2: PTree.t vardesc);
    let LOCAL2PTREE := fresh "LOCAL2PTREE" in
    assert (local2ptree Q = (T1, T2, nil, nil)) as LOCAL2PTREE;
    [subst T1 T2; prove_local2ptree |];
    first [ cast_load_tac_with_hint LOCAL2PTREE | cast_load_tac_no_hint LOCAL2PTREE | SEP_type_contradict LOCAL2PTREE e R | hint_msg LOCAL2PTREE e];
    clear T1 T2 LOCAL2PTREE
  end.

Lemma data_equal_congr {cs: compspecs}:
    forall T (v1 v2: reptype T),
   v1 = v2 ->
   data_equal v1 v2.
Proof. intros. subst. intro. reflexivity.
Qed.

Ltac store_tac_with_hint LOCAL2PTREE :=
  eapply semax_PTree_field_store_with_hint;
  [ exact LOCAL2PTREE
  | reflexivity
  | reflexivity
  | solve_msubst_eval_expr
  | solve_msubst_eval_lvalue
  | eassumption (* This line can fail. If it does not, the following should not fail. *)
  | (reflexivity                            || fail 1000 "unexpected failure in store_tac_with_hint."
                                                         "The hint does not type match")
  | (search_field_at_in_SEP                 || fail 1000 "unexpected failure in store_tac_with_hint."
                                                         "Required field_at does not exists in SEP")
  | (auto                                   || fail 1000 "unexpected failure in store_tac_with_hint."
                                                         "Cannot prove writable_share")
  | (apply JMeq_refl                        || fail 1000 "unexpected failure in store_tac_with_hint."
                                                         "unexpected failure in converting stored value")
  | first [apply data_equal_congr; solve_store_rule_evaluation
                                             | fail 1000 "unexpected failure in store_tac_with_hint."
                                                         "unexpected failure in computing stored result"]
  | first [entailer_for_store_tac            | fail 1000 "unexpected failure in store_tac_with_hint."
                                                         "unexpected failure in entailer_for_store_tac"]
  ].

Ltac store_tac_no_hint LOCAL2PTREE :=
  eapply semax_PTree_field_store_no_hint;
  [ exact LOCAL2PTREE
  | reflexivity
  | reflexivity
  | reflexivity
  | solve_msubst_eval_expr
  | solve_msubst_eval_LR
  | solve_msubst_efield_denote
  | econstructor
  | solve_field_address_gen
  | search_field_at_in_SEP (* This line can fail. If it does not, the following should not fail. *)
  | (auto                                   || fail 1000 "unexpected failure in store_tac_no_hint."
                                                         "Cannot prove writable_share")
  | (apply JMeq_refl                        || fail 1000 "unexpected failure in store_tac_no_hint."
                                                         "unexpected failure in converting stored value")
  | first [apply data_equal_congr; solve_store_rule_evaluation
                                             | fail 1000 "unexpected failure in store_tac_no_hint."
                                                         "unexpected failure in computing stored result"]
  | first [solve_legal_nested_field_in_entailment
                                             | fail 1000 "unexpected failure in store_tac_no_hint."
                                                         "unexpected failure in solve_legal_nested_field_in_entailment"]
  | first [entailer_for_store_tac            | fail 1000 "unexpected failure in store_tac_no_hint."
                                                         "unexpected failure in entailer_for_store_tac"]
  ].

Ltac store_tac :=
  match goal with
  | |- semax ?Delta (|> (PROPx ?P (LOCALx ?Q (SEPx ?R)))) (Sassign ?e1 ?e2) _ =>
    let T1 := fresh "T1" in evar (T1: PTree.t val);
    let T2 := fresh "T2" in evar (T2: PTree.t vardesc);
    let LOCAL2PTREE := fresh "LOCAL2PTREE" in
    assert (local2ptree Q = (T1, T2, nil, nil)) as LOCAL2PTREE;
    [subst T1 T2; prove_local2ptree |];
    first [ store_tac_with_hint LOCAL2PTREE | store_tac_no_hint LOCAL2PTREE | SEP_type_contradict LOCAL2PTREE e1 R | hint_msg LOCAL2PTREE e1];
    clear T1 T2 LOCAL2PTREE
  end.

