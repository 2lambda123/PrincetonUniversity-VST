Require Import VST.msl.msl_standard.
Require Import VST.veric.base.
Require Import VST.veric.compcert_rmaps.
Require Import VST.veric.Clight_lemmas.
Require Import VST.veric.tycontext.
Require Import VST.veric.expr2.
Require Import VST.veric.Cop2.
Require Import VST.veric.binop_lemmas2.
Import Cop.

Lemma denote_tc_nonzero_e:
 forall i m, app_pred (denote_tc_nonzero (Vint i)) m -> Int.eq i Int.zero = false.
Proof.
simpl; intros . destruct (Int.eq i Int.zero); auto; contradiction.
Qed.

Lemma denote_tc_nodivover_e:
 forall i j m, app_pred (denote_tc_nodivover (Vint i) (Vint j)) m ->
   Int.eq i (Int.repr Int.min_signed) && Int.eq j Int.mone = false.
Proof.
simpl; intros.
destruct (Int.eq i (Int.repr Int.min_signed) && Int.eq j Int.mone); try reflexivity; contradiction.
Qed.

Lemma denote_tc_nonzero_e64:
 forall i m, app_pred (denote_tc_nonzero (Vlong i)) m -> Int64.eq i Int64.zero = false.
Proof.
simpl; intros . destruct (Int64.eq i Int64.zero); auto; contradiction.
Qed.

Lemma denote_tc_nodivover_e64_ll:
 forall i j m, app_pred (denote_tc_nodivover (Vlong i) (Vlong j)) m ->
   Int64.eq i (Int64.repr Int64.min_signed) && Int64.eq j Int64.mone = false.
Proof.
simpl; intros.
destruct (Int64.eq i (Int64.repr Int64.min_signed) && Int64.eq j Int64.mone); try reflexivity; contradiction.
Qed.

Lemma denote_tc_nodivover_e64_il:
 forall s i j m, app_pred (denote_tc_nodivover (Vint i) (Vlong j)) m ->
   Int64.eq (cast_int_long s i) (Int64.repr Int64.min_signed) && Int64.eq j Int64.mone = false.
Proof.
simpl; intros.
destruct (Int64.eq (cast_int_long s i) (Int64.repr Int64.min_signed) && Int64.eq j Int64.mone); try reflexivity; contradiction.
Qed.

Lemma denote_tc_nodivover_e64_li:
 forall s i j m, app_pred (denote_tc_nodivover (Vlong i) (Vint j)) m ->
   Int64.eq i (Int64.repr Int64.min_signed) && Int64.eq (cast_int_long s j) Int64.mone = false.
Proof.
simpl; intros.
destruct (Int64.eq i (Int64.repr Int64.min_signed) && Int64.eq (cast_int_long s j) Int64.mone); try reflexivity; contradiction.
Qed.

Lemma Int64_eq_repr_signed32_nonzero:
  forall i, Int.eq i Int.zero = false ->
             Int64.eq (Int64.repr (Int.signed i)) Int64.zero = false.
Proof.
intros.
pose proof (Int.eq_spec i Int.zero). rewrite H in H0. clear H.
rewrite Int64.eq_false; auto.
contradict H0.
unfold Int64.zero in H0.
assert (Int64.signed (Int64.repr (Int.signed i)) = Int64.signed (Int64.repr 0)) by (f_equal; auto).
rewrite Int64.signed_repr in H.
rewrite Int64.signed_repr in H.
rewrite <- (Int.repr_signed i).
rewrite H. reflexivity.
pose proof (Int64.signed_range Int64.zero).
rewrite Int64.signed_zero in H1.
auto.
pose proof (Int.signed_range i).
clear - H1.
destruct H1.
split.
apply Z.le_trans with Int.min_signed; auto.
compute; congruence.
apply Z.le_trans with Int.max_signed; auto.
compute; congruence.
Qed.


Lemma Int64_eq_repr_unsigned32_nonzero:
  forall i, Int.eq i Int.zero = false ->
             Int64.eq (Int64.repr (Int.unsigned i)) Int64.zero = false.
Proof.
intros.
pose proof (Int.eq_spec i Int.zero). rewrite H in H0. clear H.
rewrite Int64.eq_false; auto.
contradict H0.
unfold Int64.zero in H0.
assert (Int64.unsigned (Int64.repr (Int.unsigned i)) = Int64.unsigned (Int64.repr 0)) by (f_equal; auto).
rewrite Int64.unsigned_repr in H.
rewrite Int64.unsigned_repr in H.
rewrite <- (Int.repr_unsigned i).
rewrite H. reflexivity.
split; compute; congruence.
pose proof (Int.unsigned_range i).
clear - H1.
destruct H1.
split; auto.
unfold Int64.max_unsigned.
apply Z.le_trans with Int.modulus.
omega.
compute; congruence.
Qed.

Lemma Int64_eq_repr_int_nonzero:
  forall s i, Int.eq i Int.zero = false ->
    Int64.eq (cast_int_long s i) Int64.zero = false.
Proof.
  intros.
  destruct s.
  + apply Int64_eq_repr_signed32_nonzero; auto.
  + apply Int64_eq_repr_unsigned32_nonzero; auto.
Qed.

Lemma denote_tc_igt_e:
  forall m i j, app_pred (denote_tc_igt j (Vint i)) m ->
        Int.ltu i j = true.
Proof.
intros.
hnf in H. destruct (Int.ltu i j); auto; contradiction.
Qed.

Lemma denote_tc_lgt_e:
  forall m i j, app_pred (denote_tc_lgt j (Vlong i)) m ->
        Int64.ltu i j = true.
Proof.
intros.
hnf in H. destruct (Int64.ltu i j); auto; contradiction.
Qed.

Lemma denote_tc_iszero_long_e:
 forall m i,
  app_pred (denote_tc_iszero (Vlong i)) m ->
  Int.eq (Int.repr (Int64.unsigned i)) Int.zero = true.
Proof.
intros.
hnf in H.
destruct (Int.eq (Int.repr (Int64.unsigned i)) Int.zero);
  auto; contradiction.
Qed.

Lemma sem_cmp_pp_pp:
  forall c b i b0 i0 ii ss aa
    (OP: c = Ceq \/ c = Cne),
    tc_val
      (Tint ii ss aa)
        match sem_cmp_pp c (Vptr b i) (Vptr b0 i0) with
        | Some v' => v'
        | None => Vundef
        end.
Proof.
intros; destruct OP; subst; unfold sem_cmp_pp; simpl.
+ destruct (eq_block b b0); [ destruct (Int.eq i i0) |];
  destruct ii,ss; simpl; try split; auto;
  rewrite <- Z.leb_le; reflexivity.
+ destruct (eq_block b b0); [ destruct (Int.eq i i0) |];
  destruct ii,ss; simpl; try split; auto;
  rewrite <- Z.leb_le; reflexivity.
Qed.

Lemma sem_cmp_pp_pp':
  forall c b i b0 i0 ii ss aa m
    (OP: c = Cle \/ c = Clt \/ c = Cge \/ c = Cgt),
    (denote_tc_test_order (Vptr b i) (Vptr b0 i0)) m ->
    tc_val (Tint ii ss aa)
      match sem_cmp_pp c (Vptr b i) (Vptr b0 i0) with
      | Some v' => v'
      | None => Vundef
      end.
Proof.
  intros; destruct OP as [| [| [|]]]; subst; unfold sem_cmp_pp; simpl;
  unfold denote_tc_test_order, test_order_ptrs in H; simpl in H.
  + unfold eq_block.
    destruct (peq b b0); [subst | inv H].
    simpl.
    destruct (Int.ltu i0 i);
    destruct ii,ss; simpl; try split; auto;
    rewrite <- Z.leb_le; reflexivity.
  + unfold eq_block.
    destruct (peq b b0); [subst | inv H].
    simpl.
    destruct (Int.ltu i i0);
    destruct ii,ss; simpl; try split; auto;
    rewrite <- Z.leb_le; reflexivity.
  + unfold eq_block.
    destruct (peq b b0); [subst | inv H].
    simpl.
    destruct (Int.ltu i i0);
    destruct ii,ss; simpl; try split; auto;
    rewrite <- Z.leb_le; reflexivity.
  + unfold eq_block.
    destruct (peq b b0); [subst | inv H].
    simpl.
    destruct (Int.ltu i0 i);
    destruct ii,ss; simpl; try split; auto;
    rewrite <- Z.leb_le; reflexivity.
Qed.

Lemma sem_cmp_pp_ip:
  forall c b i i0 ii ss aa
    (OP: c = Ceq \/ c = Cne),
  i = Int.zero ->
 tc_val (Tint ii ss aa)
  match sem_cmp_pp c (Vint i)  (Vptr b i0)  with
  | Some v' => v'
  | None => Vundef
  end.
Proof.
  intros; destruct OP; subst; unfold sem_cmp_pp; simpl.
  + rewrite Int.eq_true.
    destruct ii,ss; simpl; try split; auto;
    rewrite <- Z.leb_le; reflexivity.
  + rewrite Int.eq_true.
    destruct ii,ss; simpl; try split; auto;
    rewrite <- Z.leb_le; reflexivity.
Qed.

Lemma sem_cmp_pp_pi:
  forall c b i i0 ii ss aa
    (OP: c = Ceq \/ c = Cne),
  i = Int.zero ->
 tc_val (Tint ii ss aa)
  match sem_cmp_pp c (Vptr b i0)  (Vint i)  with
  | Some v' => v'
  | None => Vundef
  end.
Proof.
  intros; destruct OP; subst; unfold sem_cmp_pp; simpl.
  + rewrite Int.eq_true.
    destruct ii,ss; simpl; try split; auto;
    rewrite <- Z.leb_le; reflexivity.
  + rewrite Int.eq_true.
    destruct ii,ss; simpl; try split; auto;
    rewrite <- Z.leb_le; reflexivity.
Qed.

Lemma eq_block_true: forall b1 b2 i1 i2 A (a b: A),
    is_true (sameblock (Vptr b1 i1) (Vptr b2 i2)) ->
    (if eq_block b1 b2 then a else b) = a.
Proof.
  unfold sameblock, eq_block.
  intros.
  apply is_true_e in H.
  destruct (peq b1 b2); auto.
  inv H.
Qed.

Lemma sizeof_range_true {CS: composite_env}: forall t A (a b: A),
    negb (Z.eqb (sizeof t) 0) = true ->
    Z.leb (sizeof t) Int.max_signed = true ->
    (if zlt 0 (sizeof t) && zle (sizeof t) Int.max_signed then a else b) = a.
Proof.
  intros.
  rewrite negb_true_iff in H.
  rewrite Z.eqb_neq in H.
  pose proof sizeof_pos t.
  rewrite <- Zle_is_le_bool in H0.
  destruct (zlt 0 (sizeof t)); [| omega].
  destruct (zle (sizeof t) Int.max_signed); [| omega]. 
  reflexivity.
Qed.

Inductive tc_val_PM: type -> val -> Prop :=
| tc_val_PM_Tint: forall sz sg a v, is_int sz sg v -> tc_val_PM (Tint sz sg a) v
| tc_val_PM_Tlong: forall s a v, is_long v -> tc_val_PM (Tlong s a) v
| tc_val_PM_Tfloat_single: forall a v, is_single v -> tc_val_PM (Tfloat F32 a) v
| tc_val_PM_Tfloat_double: forall a v, is_float v -> tc_val_PM (Tfloat F64 a) v
| tc_val_PM_Tpointer: forall t a v, 
          (if eqb_type (Tpointer t a) int_or_ptr_type
           then is_pointer_or_integer
           else is_pointer_or_null) v -> 
          tc_val_PM (Tpointer t a) v
| tc_val_PM_Tarray: forall t n a v, is_pointer_or_null v -> tc_val_PM (Tarray t n a) v
| tc_val_PM_Tfunction: forall ts t a v, is_pointer_or_null v -> tc_val_PM (Tfunction ts t a) v
| tc_val_PM_Tstruct: forall i a v, isptr v -> tc_val_PM (Tstruct i a) v
| tc_val_PM_Tunion: forall i a v, isptr v -> tc_val_PM (Tunion i a) v.

Lemma tc_val_tc_val_PM: forall t v, tc_val t v <-> tc_val_PM t v.
Proof.
  intros.
  split; intros.
  + destruct t as [| | | [ | ] ? | | | | |]; try (inv H); constructor; auto.
  + inversion H; subst; auto.
Qed.

Inductive tc_val_PM': type -> val -> Prop :=
| tc_val_PM'_Tint: forall t0 sz sg a v, stupid_typeconv t0 = Tint sz sg a -> is_int sz sg v -> tc_val_PM' t0 v
| tc_val_PM'_Tlong: forall t0 s a v, stupid_typeconv t0 = Tlong s a -> is_long v -> tc_val_PM' t0 v
| tc_val_PM'_Tfloat_single: forall t0 a v, stupid_typeconv t0 = Tfloat F32 a -> is_single v -> tc_val_PM' t0 v
| tc_val_PM'_Tfloat_double: forall t0 a v, stupid_typeconv t0 = Tfloat F64 a -> is_float v -> tc_val_PM' t0 v
| tc_val_PM'_Tpointer: forall t0 t a v, 
  stupid_typeconv t0 = Tpointer t a -> 
  (if eqb_type t0 int_or_ptr_type
           then is_pointer_or_integer
           else is_pointer_or_null) v -> 
  tc_val_PM' t0 v
| tc_val_PM'_Tstruct: forall t0 i a v, stupid_typeconv t0 = Tstruct i a -> isptr v -> tc_val_PM' t0 v
| tc_val_PM'_Tunion: forall t0 i a v, stupid_typeconv t0 = Tunion i a -> isptr v -> tc_val_PM' t0 v.

Lemma tc_val_tc_val_PM': forall t v, tc_val t v <-> tc_val_PM' t v.
Proof.
  intros.
  split; intros.
  + destruct t as [| | | [ | ] ? | | | | |]; try (inv H).
    - eapply tc_val_PM'_Tint; eauto; reflexivity.
    - eapply tc_val_PM'_Tlong; eauto; reflexivity.
    - eapply tc_val_PM'_Tfloat_single; eauto; reflexivity.
    - eapply tc_val_PM'_Tfloat_double; eauto; reflexivity.
    - eapply tc_val_PM'_Tpointer; eauto; reflexivity.
    - eapply tc_val_PM'_Tpointer; eauto; reflexivity.
    - eapply tc_val_PM'_Tpointer; eauto; reflexivity.
    - eapply tc_val_PM'_Tstruct; eauto; reflexivity.
    - eapply tc_val_PM'_Tunion; eauto; reflexivity.
  + inversion H; subst;
    destruct t as [| | | [ | ] ? | | | | |]; try (inv H0);
    auto.
Qed.

Ltac solve_tc_val H :=
  rewrite tc_val_tc_val_PM in H; inv H.

Ltac solve_tc_val' H :=
  rewrite tc_val_tc_val_PM' in H; inv H.

Lemma tc_val_sem_binarith': forall {CS: compspecs} sem_int sem_long sem_float sem_single t1 t2 t v1 v2 deferr reterr rho m
  (TV2: tc_val t2 v2)
  (TV1: tc_val t1 v1),
  (denote_tc_assert (binarithType' t1 t2 t deferr reterr) rho) m ->
  tc_val t
    (force_val
      (Cop2.sem_binarith
        (fun s n1 n2 => Some (Vint (sem_int s n1 n2)))
        (fun s n1 n2 => Some (Vlong (sem_long s n1 n2)))
        (fun n1 n2 => Some (Vfloat (sem_float n1 n2)))
        (fun n1 n2 => Some (Vsingle (sem_single n1 n2)))
        t1 t2 v1 v2)).
Proof.
  intros.
  unfold binarithType' in H.
  unfold Cop2.sem_binarith.
  rewrite classify_binarith_eq.
  destruct (classify_binarith' t1 t2) eqn:?H;
  try solve [inv H]; apply tc_bool_e in H.
  + (* bin_case_i *)
    solve_tc_val TV1;
    solve_tc_val TV2;
    try solve [inv H0].
    destruct v1; try solve [inv H1].
    destruct v2; try solve [inv H2].
    destruct t as [| [| | |] ? ? | | | | | | |]; inv H; simpl; auto.
  + (* bin_case_l *)
    solve_tc_val TV1;
    solve_tc_val TV2;
    try solve [inv H0];
    destruct v1; try solve [inv H1];
    destruct v2; try solve [inv H2];
    destruct t as [| [| | |] ? ? | | | | | | |]; inv H; simpl; auto.
  + (* bin_case_f *)
    solve_tc_val TV1;
    solve_tc_val TV2;
    try solve [inv H0];
    destruct v1; try solve [inv H1];
    destruct v2; try solve [inv H2];
    destruct t as [| [| | |] ? ? | | [|] | | | | |]; inv H; simpl; auto.
  + (* bin_case_s *)
    solve_tc_val TV1;
    solve_tc_val TV2;
    try solve [inv H0];
    destruct v1; try solve [inv H1];
    destruct v2; try solve [inv H2];
    destruct t as [| [| | |] ? ? | | [|] | | | | |]; inv H; simpl; auto.
Qed.

Lemma tc_val_sem_cmp_binarith': forall sem_int sem_long sem_float sem_single t1 t2 t v1 v2
  (TV2: tc_val t2 v2)
  (TV1: tc_val t1 v1),
  is_numeric_type t1 = true ->
  is_numeric_type t2 = true ->
  is_int_type t = true ->
  tc_val t
    (force_val
      (Cop2.sem_binarith
        (fun s n1 n2 => Some (Val.of_bool (sem_int s n1 n2)))
        (fun s n1 n2 => Some (Val.of_bool (sem_long s n1 n2)))
        (fun n1 n2 => Some (Val.of_bool (sem_float n1 n2)))
        (fun n1 n2 => Some (Val.of_bool (sem_single n1 n2)))
        t1 t2 v1 v2)).
Proof.
  intros.
  destruct t; inv H1.
  unfold Cop2.sem_binarith.
  rewrite classify_binarith_eq.
  destruct (classify_binarith' t1 t2) eqn:?H.
  + (* bin_case_i *)
    solve_tc_val TV1;
    solve_tc_val TV2;
    try solve [inv H1].
    destruct v1; try solve [inv H2];
    destruct v2; try solve [inv H3].
    apply tc_val_of_bool.
  + (* bin_case_l *)
    solve_tc_val TV1;
    solve_tc_val TV2;
    try solve [inv H1];
    destruct v1; try solve [inv H2];
    destruct v2; try solve [inv H3];
    apply tc_val_of_bool.
  + (* bin_case_f *)
    solve_tc_val TV1;
    solve_tc_val TV2;
    try solve [inv H1];
    destruct v1; try solve [inv H2];
    destruct v2; try solve [inv H3];
    apply tc_val_of_bool.
  + (* bin_case_s *)
    solve_tc_val TV1;
    solve_tc_val TV2;
    try solve [inv H1];
    destruct v1; try solve [inv H2];
    destruct v2; try solve [inv H3];
    apply tc_val_of_bool.
  + unfold classify_binarith' in H1.
    solve_tc_val TV1;
    solve_tc_val TV2;
    inv H1; inv H; inv H0.
Qed.

Lemma negb_true: forall a, negb a = true -> a = false.
Proof.  intros; destruct a; auto; inv H. Qed.

Lemma typecheck_Oadd_sound:
forall {CS: compspecs} (rho : environ) m (e1 e2 : expr) (t : type)
   (IBR: denote_tc_assert (isBinOpResultType Oadd e1 e2 t) rho m)
   (TV2: tc_val (typeof e2) (eval_expr e2 rho))
   (TV1: tc_val (typeof e1) (eval_expr e1 rho)),
   tc_val t
     (eval_binop Oadd (typeof e1) (typeof e2)
       (eval_expr e1 rho) (eval_expr e2 rho)).
Proof.
  intros.
  rewrite den_isBinOpR in IBR. 
  unfold tc_int_or_ptr_type, eval_binop, sem_binary_operation', isBinOpResultType, Cop2.sem_add in IBR |- *.
  rewrite classify_add_eq.
  destruct (classify_add' (typeof e1) (typeof e2)) eqn:?H;
  unfold force_val2, force_val;
  rewrite tc_val_tc_val_PM in TV1,TV2|-*;
  unfold classify_add' in H; simpl in IBR;
    repeat match goal with
    | H: _ /\ _ |- _ => destruct H
    | H: app_pred (denote_tc_assert (tc_bool _ _) _) _ |- _ => 
                      apply tc_bool_e in H
    | H: negb (eqb_type ?A ?B) = true |- _ =>
             let J := fresh "J" in
              destruct (eqb_type A B) eqn:J; [inv H | clear H]              
    end;
  try solve [
    unfold is_pointer_type in H1;
    destruct (typeof e1); inv TV1; destruct (typeof e2); inv TV2;
    simpl in H; inv H;
    try rewrite J in *; clear J;
    destruct (eval_expr e1 rho), (eval_expr e2 rho);
     simpl in *; try contradiction;
    destruct t; try solve [inv H1];
    try solve [constructor; try rewrite (negb_true _ H1); apply I]
  ].
  rewrite denote_tc_assert_andp in IBR. destruct IBR.
  unfold sem_add_default.
  rewrite <- tc_val_tc_val_PM in TV1,TV2|-*.
  eapply tc_val_sem_binarith'; eauto.
Qed.

Lemma peq_eq_block:
   forall a b A (c d: A), is_true (peq a b) ->
       (if eq_block a b then c else d) = c.
 Proof.
  intros. rewrite if_true; auto.
   destruct (peq a b); auto. inv H.
 Qed.

Lemma typecheck_Osub_sound:
forall {CS: compspecs} (rho : environ) m (e1 e2 : expr) (t : type)
   (IBR: denote_tc_assert (isBinOpResultType Osub e1 e2 t) rho m)
   (TV2: tc_val (typeof e2) (eval_expr e2 rho))
   (TV1: tc_val (typeof e1) (eval_expr e1 rho)),
   tc_val t
     (eval_binop Osub (typeof e1) (typeof e2)
       (eval_expr e1 rho) (eval_expr e2 rho)).
Proof.
  intros.
  rewrite den_isBinOpR in IBR. 
  unfold tc_int_or_ptr_type, eval_binop, sem_binary_operation', isBinOpResultType, Cop2.sem_sub in IBR |- *.
  rewrite classify_sub_eq.
  destruct (classify_sub' (typeof e1) (typeof e2)) eqn:?H;
  unfold force_val2, force_val;
  rewrite tc_val_tc_val_PM in TV1,TV2|-*;
  unfold classify_sub' in H; simpl in IBR;
    repeat match goal with
    | H: _ /\ _ |- _ => destruct H
    | H: app_pred (denote_tc_assert (tc_bool _ _) _) _ |- _ => 
                      apply tc_bool_e in H
    | H: negb (eqb_type ?A ?B) = true |- _ =>
             let J := fresh "J" in
              destruct (eqb_type A B) eqn:J; [inv H | clear H]              
    end;
  try solve [
    unfold is_pointer_type in H1;
    destruct (typeof e1); inv TV1; destruct (typeof e2); inv TV2;
    simpl in H; inv H;
    try rewrite J in *; clear J;
    destruct (eval_expr e1 rho), (eval_expr e2 rho);
     simpl in *; try contradiction;
    destruct t; try solve [inv H1];
    try solve [constructor; try rewrite (negb_true _ H1); apply I]
  ].
 +
    destruct (typeof e1); inv TV1; destruct (typeof e2); inv TV2;
    simpl in H; inv H;
    rewrite ?J, ?J0 in *; clear J J0;
    destruct (eval_expr e1 rho), (eval_expr e2 rho);
     simpl in *; try contradiction;
    destruct t as [| [| | |] [|] | | | | | | |]; inv H4;
    simpl; constructor;
    try (rewrite peq_eq_block by auto; 
           rewrite sizeof_range_true by auto);
    try discriminate;
    try apply I.
 +
  rewrite <- tc_val_tc_val_PM in TV1,TV2|-*.
  rewrite denote_tc_assert_andp in IBR. destruct IBR.
  eapply tc_val_sem_binarith'; eauto.
Qed.

Lemma typecheck_Omul_sound:
forall {CS: compspecs} (rho : environ) m (e1 e2 : expr) (t : type)
   (IBR: denote_tc_assert (isBinOpResultType Omul e1 e2 t) rho m)
   (TV2: tc_val (typeof e2) (eval_expr e2 rho))
   (TV1: tc_val (typeof e1) (eval_expr e1 rho)),
   tc_val t
     (eval_binop Omul (typeof e1) (typeof e2)
       (eval_expr e1 rho) (eval_expr e2 rho)).
Proof.
  intros.
  rewrite den_isBinOpR in IBR.
  unfold eval_binop, sem_binary_operation', isBinOpResultType, Cop2.sem_mul in IBR |- *.
  rewrite denote_tc_assert_andp in IBR. destruct IBR.
  unfold force_val2, force_val.
  eapply tc_val_sem_binarith'; eauto.
Qed.

Lemma typecheck_Odiv_sound:
forall {CS: compspecs} (rho : environ) m (e1 e2 : expr) (t : type)
   (IBR: denote_tc_assert (isBinOpResultType Odiv e1 e2 t) rho m)
   (TV2: tc_val (typeof e2) (eval_expr e2 rho))
   (TV1: tc_val (typeof e1) (eval_expr e1 rho)),
   tc_val t
     (eval_binop Odiv (typeof e1) (typeof e2)
       (eval_expr e1 rho) (eval_expr e2 rho)).
Proof.
  intros.
  rewrite den_isBinOpR in IBR.
  unfold eval_binop, sem_binary_operation', isBinOpResultType, Cop2.sem_mul in IBR |- *.
  unfold force_val2, force_val.
  eapply (tc_val_sem_binarith' _ _ _ _ _ _ _ _ _ _ _ rho m); eauto.
  unfold binarithType'.
  destruct (classify_binarith' (typeof e1) (typeof e2)); eauto.
  + destruct s; destruct IBR; eauto.
  + destruct s; destruct IBR; eauto.
Qed.

Lemma typecheck_Omod_sound:
forall {CS: compspecs} (rho : environ) m (e1 e2 : expr) (t : type)
   (IBR: denote_tc_assert (isBinOpResultType Omod e1 e2 t) rho m)
   (TV2: tc_val (typeof e2) (eval_expr e2 rho))
   (TV1: tc_val (typeof e1) (eval_expr e1 rho)),
   tc_val t
     (eval_binop Omod (typeof e1) (typeof e2)
       (eval_expr e1 rho) (eval_expr e2 rho)).
Proof.
  intros.
  rewrite den_isBinOpR in IBR.
  unfold eval_binop, sem_binary_operation', isBinOpResultType, Cop2.sem_mod in IBR |- *.
  unfold force_val2, force_val.
  unfold Cop2.sem_binarith.
  rewrite classify_binarith_eq.
  destruct (classify_binarith' (typeof e1) (typeof e2)) eqn:?H.
  + solve_tc_val TV1;
    solve_tc_val TV2;
    rewrite <- H2, <- H0 in H;
    try solve [inv H].
    destruct s; destruct IBR as [?IBR ?IBR].
    - destruct IBR as [?IBR ?IBR].
      apply tc_bool_e in IBR0.
      simpl in IBR, IBR1 |- *; unfold_lift in IBR; unfold_lift in IBR1.
      destruct (eval_expr e1 rho), (eval_expr e2 rho);
      try solve [inv H1 | inv H3 | inv IBR].
      unfold both_int; simpl.
      apply denote_tc_nonzero_e in IBR; try rewrite IBR.
      apply denote_tc_nodivover_e in IBR1; try rewrite IBR1.
      simpl.
      destruct t as [| [| | |] ? ? | | | | | | |]; try solve [inv IBR0];
      simpl; auto.
    - apply tc_bool_e in IBR0.
      simpl in IBR |- *; unfold_lift in IBR.
      destruct (eval_expr e1 rho), (eval_expr e2 rho);
      try solve [inv H1 | inv H3 | inv IBR].
      unfold both_int; simpl.
      apply denote_tc_nonzero_e in IBR; try rewrite IBR.
      simpl.
      destruct t as [| [| | |] ? ? | | | | | | |]; try solve [inv IBR0];
      simpl; auto.
  + solve_tc_val TV1;
    solve_tc_val TV2;
    rewrite <- H2, <- H0 in H;
    try solve [inv H].
    - (* int long *)
      destruct s; destruct IBR as [?IBR ?IBR].
      * destruct IBR as [?IBR ?IBR].
        apply tc_bool_e in IBR0.
        simpl in IBR, IBR1 |- *; unfold_lift in IBR; unfold_lift in IBR1.
        destruct (eval_expr e1 rho), (eval_expr e2 rho);
          try solve [inv H1 | inv H3].
        unfold both_long; simpl.
        apply denote_tc_nonzero_e64 in IBR; try rewrite IBR.
        apply (denote_tc_nodivover_e64_il sg) in IBR1; try rewrite IBR1.
        simpl.
        destruct t as [| [| | |] ? ? | | | | | | |]; try solve [inv IBR0];
        simpl; auto.
      * apply tc_bool_e in IBR0.
        simpl in IBR |- *; unfold_lift in IBR.
        destruct (eval_expr e1 rho), (eval_expr e2 rho);
        try solve [inv H1 | inv H3 | inv IBR].
        unfold both_long; simpl.
        apply denote_tc_nonzero_e64 in IBR; try rewrite IBR.
        destruct t as [| [| | |] ? ? | | | | | | |]; try solve [inv IBR0];
        simpl; auto.
    - (* long int *)
      destruct s; destruct IBR as [?IBR ?IBR].
      * destruct IBR as [?IBR ?IBR].
        apply tc_bool_e in IBR0.
        simpl in IBR, IBR1 |- *; unfold_lift in IBR; unfold_lift in IBR1.
        destruct (eval_expr e1 rho), (eval_expr e2 rho);
          try solve [inv H1 | inv H3].
        unfold both_long; simpl.
        apply denote_tc_nonzero_e, (Int64_eq_repr_int_nonzero sg) in IBR; try rewrite IBR.
        apply (denote_tc_nodivover_e64_li sg) in IBR1; try rewrite IBR1.
        simpl.
        destruct t as [| [| | |] ? ? | | | | | | |]; try solve [inv IBR0];
        simpl; auto.
      * apply tc_bool_e in IBR0.
        simpl in IBR |- *; unfold_lift in IBR.
        destruct (eval_expr e1 rho), (eval_expr e2 rho);
        try solve [inv H1 | inv H3 | inv IBR].
        unfold both_long; simpl.
        apply denote_tc_nonzero_e, (Int64_eq_repr_int_nonzero sg) in IBR; try rewrite IBR.
        destruct t as [| [| | |] ? ? | | | | | | |]; try solve [inv IBR0];
        simpl; auto.
    - (* long long *)
      destruct s; destruct IBR as [?IBR ?IBR].
      * destruct IBR as [?IBR ?IBR].
        apply tc_bool_e in IBR0.
        simpl in IBR, IBR1 |- *; unfold_lift in IBR; unfold_lift in IBR1.
        destruct (eval_expr e1 rho), (eval_expr e2 rho);
          try solve [inv H1 | inv H3].
        unfold both_long; simpl.
        apply denote_tc_nonzero_e64 in IBR; try rewrite IBR.
        apply denote_tc_nodivover_e64_ll in IBR1; try rewrite IBR1.
        simpl.
        destruct t as [| [| | |] ? ? | | | | | | |]; try solve [inv IBR0];
        simpl; auto.
      * apply tc_bool_e in IBR0.
        simpl in IBR |- *; unfold_lift in IBR.
        destruct (eval_expr e1 rho), (eval_expr e2 rho);
        try solve [inv H1 | inv H3 | inv IBR].
        unfold both_long; simpl.
        apply denote_tc_nonzero_e64 in IBR; try rewrite IBR.
        destruct t as [| [| | |] ? ? | | | | | | |]; try solve [inv IBR0];
        simpl; auto.
  + inv IBR.
  + inv IBR.
  + inv IBR.
Qed.

Lemma typecheck_Oshift_sound:
 forall op {CS: compspecs} (rho : environ) m (e1 e2 : expr) (t : type)
   (IBR: denote_tc_assert (isBinOpResultType op e1 e2 t) rho m)
   (TV2: tc_val (typeof e2) (eval_expr e2 rho))
   (TV1: tc_val (typeof e1) (eval_expr e1 rho))
   (OP: op = Oshl \/ op = Oshr),
   tc_val t
     (eval_binop op (typeof e1) (typeof e2) (eval_expr e1 rho) (eval_expr e2 rho)).
Proof.
  intros.
  replace
    ((denote_tc_assert (isBinOpResultType op e1 e2 t) rho) m)
  with
    ((denote_tc_assert
           match classify_shift' (typeof e1) (typeof e2) with
           | shift_case_ii _ =>
               tc_andp' (tc_ilt' e2 Int.iwordsize)
                 (tc_bool (is_int32_type t) (op_result_type (Ebinop op e1 e2 t)))
           | shift_case_il _ =>
               tc_andp' (tc_llt' e2 (Int64.repr 32))
                 (tc_bool (is_int32_type t) (op_result_type (Ebinop op e1 e2 t)))
           | shift_case_li _ =>
               tc_andp' (tc_ilt' e2 Int64.iwordsize')
                 (tc_bool (is_long_type t) (op_result_type (Ebinop op e1 e2 t)))
           | shift_case_ll _ =>
               tc_andp' (tc_llt' e2 Int64.iwordsize)
                 (tc_bool (is_long_type t) (op_result_type (Ebinop op e1 e2 t)))
           | _ => tc_FF (arg_type (Ebinop op e1 e2 t))
           end rho) m)
  in IBR
  by (rewrite den_isBinOpR; destruct OP; subst; auto).
  destruct (classify_shift' (typeof e1) (typeof e2)) eqn:?H; try solve [inv IBR].
  + (* shift_ii *)
    destruct IBR as [?IBR ?IBR].
    apply tc_bool_e in IBR0.
    simpl in IBR; unfold_lift in IBR.
    solve_tc_val TV1;
    solve_tc_val TV2;
    rewrite <- H0, <- H2 in H;
    try solve [inv H].
    destruct (eval_expr e1 rho), (eval_expr e2 rho);
      try solve [inv H1 | inv H3].
    destruct OP; subst; auto;
    simpl;
    unfold force_val, Cop2.sem_shift;
    rewrite classify_shift_eq, H;
    simpl.
    - rewrite (denote_tc_igt_e m) by assumption;
      destruct t as [| [| | |] ? ? | | | | | | |]; try solve [inv IBR0]; simpl; auto.
    - rewrite (denote_tc_igt_e m) by assumption;
      destruct t as [| [| | |] ? ? | | | | | | |]; try solve [inv IBR0]; simpl; auto.
  + (* shift_ll *)
    destruct IBR as [?IBR ?IBR].
    apply tc_bool_e in IBR0.
    simpl in IBR; unfold_lift in IBR.
    solve_tc_val TV1;
    solve_tc_val TV2;
    rewrite <- H0, <- H2 in H;
    try solve [inv H].
    destruct (eval_expr e1 rho), (eval_expr e2 rho);
      try solve [inv H1 | inv H3].
    destruct OP; subst; auto;
    simpl;
    unfold force_val, Cop2.sem_shift;
    rewrite classify_shift_eq, H;
    simpl.
    - rewrite (denote_tc_lgt_e m) by assumption;
      destruct t as [| [| | |] ? ? | | | | | | |]; try solve [inv IBR0]; simpl; auto.
    - rewrite (denote_tc_lgt_e m) by assumption;
      destruct t as [| [| | |] ? ? | | | | | | |]; try solve [inv IBR0]; simpl; auto.
  + (* shift_il *)
    destruct IBR as [?IBR ?IBR].
    apply tc_bool_e in IBR0.
    simpl in IBR; unfold_lift in IBR.
    solve_tc_val TV1;
    solve_tc_val TV2;
    rewrite <- H0, <- H2 in H;
    try solve [inv H].
    destruct (eval_expr e1 rho), (eval_expr e2 rho);
      try solve [inv H1 | inv H3].
    destruct OP; subst; auto;
    simpl;
    unfold force_val, Cop2.sem_shift;
    rewrite classify_shift_eq, H;
    simpl.
    - rewrite (denote_tc_lgt_e m) by assumption;
      destruct t as [| [| | |] ? ? | | | | | | |]; try solve [inv IBR0]; simpl; auto.
    - rewrite (denote_tc_lgt_e m) by assumption;
      destruct t as [| [| | |] ? ? | | | | | | |]; try solve [inv IBR0]; simpl; auto.
  + (* shift_li *)
    destruct IBR as [?IBR ?IBR].
    apply tc_bool_e in IBR0.
    simpl in IBR; unfold_lift in IBR.
    solve_tc_val TV1;
    solve_tc_val TV2;
    rewrite <- H0, <- H2 in H;
    try solve [inv H].
    destruct (eval_expr e1 rho), (eval_expr e2 rho);
      try solve [inv H1 | inv H3].
    destruct OP; subst; auto;
    simpl;
    unfold force_val, Cop2.sem_shift;
    rewrite classify_shift_eq, H;
    simpl.
    - rewrite (denote_tc_igt_e m) by assumption;
      destruct t as [| [| | |] ? ? | | | | | | |]; try solve [inv IBR0]; simpl; auto.
    - rewrite (denote_tc_igt_e m) by assumption;
      destruct t as [| [| | |] ? ? | | | | | | |]; try solve [inv IBR0]; simpl; auto.
Qed.

Lemma typecheck_Obin_sound:
 forall op {CS: compspecs} (rho : environ) m (e1 e2 : expr) (t : type)
   (IBR: denote_tc_assert (isBinOpResultType op e1 e2 t) rho m)
   (TV2: tc_val (typeof e2) (eval_expr e2 rho))
   (TV1: tc_val (typeof e1) (eval_expr e1 rho))
   (OP: op = Oand \/ op = Oor \/ op = Oxor),
   tc_val t
     (eval_binop op (typeof e1) (typeof e2) (eval_expr e1 rho) (eval_expr e2 rho)).
Proof.
  intros.
  replace
    ((denote_tc_assert (isBinOpResultType op e1 e2 t) rho) m)
  with
    ((denote_tc_assert
           match classify_binarith' (typeof e1) (typeof e2) with
           | bin_case_i _ => tc_bool (is_int32_type t) (op_result_type (Ebinop op e1 e2 t))
           | bin_case_l _ => tc_bool (is_long_type t) (op_result_type (Ebinop op e1 e2 t))
           | _ => tc_FF (arg_type (Ebinop op e1 e2 t))
           end rho) m)
  in IBR
  by (rewrite den_isBinOpR; destruct OP as [| [ | ]]; subst; auto).
  destruct (classify_binarith' (typeof e1) (typeof e2)) eqn:?H; try solve [inv IBR].
  + (* bin_case_i *)
    apply tc_bool_e in IBR.
    simpl in IBR; unfold_lift in IBR.
    solve_tc_val TV1;
    solve_tc_val TV2;
    rewrite <- H0, <- H2 in H;
    try solve [inv H].
    destruct (eval_expr e1 rho), (eval_expr e2 rho);
      try solve [inv H1 | inv H3].
    destruct OP as [| [|]]; subst; auto;
    simpl;
    unfold force_val, Cop2.sem_and, Cop2.sem_or, Cop2.sem_xor, Cop2.sem_binarith;
    rewrite classify_binarith_eq, H;
    simpl;
    destruct t as [| [| | |] ? ? | | | | | | |]; try solve [inv IBR]; simpl; auto.
  + (* bin_case_l *)
    apply tc_bool_e in IBR.
    simpl in IBR; unfold_lift in IBR.
    solve_tc_val TV1;
    solve_tc_val TV2;
    rewrite <- H0, <- H2 in H;
    try solve [inv H].
    - destruct (eval_expr e1 rho), (eval_expr e2 rho);
        try solve [inv H1 | inv H3].
      destruct OP as [| [|]]; subst; auto;
      simpl;
      unfold force_val, Cop2.sem_and, Cop2.sem_or, Cop2.sem_xor, Cop2.sem_binarith;
      rewrite classify_binarith_eq, H;
      simpl;
      destruct t as [| [| | |] ? ? | | | | | | |]; try solve [inv IBR]; simpl; auto.
    - destruct (eval_expr e1 rho), (eval_expr e2 rho);
        try solve [inv H1 | inv H3].
      destruct OP as [| [|]]; subst; auto;
      simpl;
      unfold force_val, Cop2.sem_and, Cop2.sem_or, Cop2.sem_xor, Cop2.sem_binarith;
      rewrite classify_binarith_eq, H;
      simpl;
      destruct t as [| [| | |] ? ? | | | | | | |]; try solve [inv IBR]; simpl; auto.
    - destruct (eval_expr e1 rho), (eval_expr e2 rho);
        try solve [inv H1 | inv H3].
      destruct OP as [| [|]]; subst; auto;
      simpl;
      unfold force_val, Cop2.sem_and, Cop2.sem_or, Cop2.sem_xor, Cop2.sem_binarith;
      rewrite classify_binarith_eq, H;
      simpl;
      destruct t as [| [| | |] ? ? | | | | | | |]; try solve [inv IBR]; simpl; auto.
Qed.

Lemma denote_tc_test_eq_Vint_l: forall m i v,
  (denote_tc_test_eq (Vint i) v) m ->
  i = Int.zero.
Proof.
  intros.
  unfold denote_tc_test_eq in H; simpl in H.
  destruct v; try solve [inv H]; simpl in H; tauto.
Qed.

Lemma denote_tc_test_eq_Vint_r: forall m i v,
  (denote_tc_test_eq v (Vint i)) m ->
  i = Int.zero.
Proof.
  intros.
  unfold denote_tc_test_eq in H; simpl in H.
  destruct v; try solve [inv H]; simpl in H; tauto.
Qed.

Lemma typecheck_Otest_eq_sound:
 forall op {CS: compspecs} (rho : environ) m (e1 e2 : expr) (t : type)
   (IBR: denote_tc_assert (isBinOpResultType op e1 e2 t) rho m)
   (TV2: tc_val (typeof e2) (eval_expr e2 rho))
   (TV1: tc_val (typeof e1) (eval_expr e1 rho))
   (OP: op = Oeq \/ op = One),
   tc_val t
     (eval_binop op (typeof e1) (typeof e2) (eval_expr e1 rho) (eval_expr e2 rho)).
Proof.
  intros.
  replace
    ((denote_tc_assert (isBinOpResultType op e1 e2 t) rho) m)
  with
    ((denote_tc_assert
           match classify_cmp' (typeof e1) (typeof e2) with
           | cmp_case_pp => tc_andp' (tc_andp' (tc_int_or_ptr_type (typeof e1)) 
                                      (tc_int_or_ptr_type (typeof e2)))
                                  (check_pp_int' e1 e2 op t (Ebinop op e1 e2 t))
           | cmp_case_pl => 
                         tc_andp' (tc_int_or_ptr_type (typeof e1))
                            (check_pp_int' e1 (Ecast e2 (Tint I32 Unsigned noattr)) op t (Ebinop op e1 e2 t))
           | cmp_case_lp => 
                         tc_andp' (tc_int_or_ptr_type (typeof e2))
                            (check_pp_int' (Ecast e1 (Tint I32 Unsigned noattr)) e2 op t (Ebinop op e1 e2 t))
           | cmp_default =>
               tc_bool (is_numeric_type (typeof e1) && is_numeric_type (typeof e2) && is_int_type t)
                 (arg_type (Ebinop op e1 e2 t))
           end rho) m)
  in IBR
  by (rewrite den_isBinOpR; destruct OP as [|]; subst; auto).
  replace
    (tc_val t (eval_binop op (typeof e1) (typeof e2) (eval_expr e1 rho) (eval_expr e2 rho)))
  with
    (tc_val t
      (force_val
        (match classify_cmp' (typeof e1) (typeof e2) with
         | cmp_case_pp => if orb (eqb_type (typeof e1) int_or_ptr_type)
                                 (eqb_type (typeof e2) int_or_ptr_type) 
            then (fun _ _ => None)
            else sem_cmp_pp (op_to_cmp op)
         | cmp_case_pl => if eqb_type (typeof e1) int_or_ptr_type
            then (fun _ _ => None)
            else sem_cmp_pl (op_to_cmp op)
         | cmp_case_lp => if eqb_type (typeof e2) int_or_ptr_type
            then (fun _ _ => None)
            else sem_cmp_lp (op_to_cmp op)
         | cmp_default => sem_cmp_default (op_to_cmp op) (typeof e1) (typeof e2)
         end (eval_expr e1 rho) (eval_expr e2 rho))))
  by (destruct OP as [|]; subst; rewrite <- classify_cmp_eq; auto).
  unfold tc_int_or_ptr_type, eval_binop, sem_binary_operation', isBinOpResultType, Cop2.sem_add in IBR |- *.
  unfold force_val;
  rewrite tc_val_tc_val_PM in TV1,TV2.
  replace (check_pp_int' e1 e2 op t (Ebinop op e1 e2 t))
    with (tc_andp' (tc_test_eq' e1 e2)
                   (tc_bool (is_int_type t) (op_result_type (Ebinop op e1 e2 t))))
    in IBR
    by (unfold check_pp_int'; destruct OP; subst; auto).
  replace (check_pp_int' e1 (Ecast e2 (Tint I32 Unsigned noattr)) op t (Ebinop op e1 e2 t))
    with (tc_andp' (tc_test_eq' e1 (Ecast e2 (Tint I32 Unsigned noattr)))
                   (tc_bool (is_int_type t) (op_result_type (Ebinop op e1 e2 t))))
    in IBR
    by (unfold check_pp_int'; destruct OP; subst; auto).
  replace (check_pp_int' (Ecast e1 (Tint I32 Unsigned noattr)) e2 op t (Ebinop op e1 e2 t))
    with (tc_andp' (tc_test_eq' (Ecast e1 (Tint I32 Unsigned noattr)) e2)
                   (tc_bool (is_int_type t) (op_result_type (Ebinop op e1 e2 t))))
    in IBR
    by (unfold check_pp_int'; destruct OP; subst; auto).
  destruct (classify_cmp' (typeof e1) (typeof e2)) eqn:?H; try solve [inv IBR].
1,2,3:
  simpl in IBR; unfold_lift in IBR;
    repeat match goal with
    | H: _ /\ _ |- _ => destruct H
    | H: app_pred (denote_tc_assert (tc_bool _ _) _) _ |- _ => 
                      apply tc_bool_e in H
    | H: negb (eqb_type ?A ?B) = true |- _ =>
             let J := fresh "J" in
              destruct (eqb_type A B) eqn:J; [inv H | clear H]              
    end;
    destruct (typeof e1) as [| [| | |] [|] | | | | | | |]; inv TV1; 
    destruct (typeof e2) as [| [| | |] [|] | | | | | | |]; inv TV2;
    simpl in H; inv H;
    try (rewrite J in *; clear J);
    try (rewrite J0 in *; clear J0);
    destruct (eval_expr e1 rho), (eval_expr e2 rho);
     simpl in *; try contradiction;
    repeat match goal with H: _ /\ _ |- _ => destruct H end;
    subst;
    destruct t as [| [| | |] [|] | | | | | | |];
    try solve [inv H2];
    try apply tc_val_of_bool;
    try solve [apply sem_cmp_pp_ip; auto; destruct OP; subst; auto];
    try solve [apply sem_cmp_pp_pi; auto; destruct OP; subst; auto];
    try solve [apply sem_cmp_pp_pp; auto; destruct OP; subst; auto].

  unfold sem_cmp_default.
  apply tc_bool_e in IBR.
  rewrite !andb_true_iff in IBR.
    destruct IBR as [[?IBR ?IBR] ?IBR].
  rewrite <- tc_val_tc_val_PM in TV1,TV2.
   apply tc_val_sem_cmp_binarith'; auto.
Qed.

Lemma typecheck_Otest_order_sound:
 forall op {CS: compspecs} (rho : environ) m (e1 e2 : expr) (t : type)
   (IBR: denote_tc_assert (isBinOpResultType op e1 e2 t) rho m)
   (TV2: tc_val (typeof e2) (eval_expr e2 rho))
   (TV1: tc_val (typeof e1) (eval_expr e1 rho))
   (OP: op = Ole \/ op = Olt \/ op = Oge \/ op = Ogt),
   tc_val t
     (eval_binop op (typeof e1) (typeof e2) (eval_expr e1 rho) (eval_expr e2 rho)).
Proof.
  intros.
  replace
    ((denote_tc_assert (isBinOpResultType op e1 e2 t) rho) m)
  with
    ((denote_tc_assert
            match classify_cmp' (typeof e1) (typeof e2) with
              | cmp_default =>
                           tc_bool (is_numeric_type (typeof e1)
                                         && is_numeric_type (typeof e2)
                                          && is_int_type t)
                                             (arg_type (Ebinop op e1 e2 t))
	            | cmp_case_pp => 
                     tc_andp' (tc_andp' (tc_int_or_ptr_type (typeof e1)) 
                                      (tc_int_or_ptr_type (typeof e2)))
                       (check_pp_int' e1 e2 op t (Ebinop op e1 e2 t))
              | cmp_case_pl => 
                     tc_andp' (tc_int_or_ptr_type (typeof e1))
                       (check_pp_int' e1 (Ecast e2 (Tint I32 Unsigned noattr)) op t (Ebinop op e1 e2 t))
              | cmp_case_lp => 
                     tc_andp' (tc_int_or_ptr_type (typeof e2))
                    (check_pp_int' (Ecast e1 (Tint I32 Unsigned noattr)) e2 op t (Ebinop op e1 e2 t))
              end rho) m)
  in IBR
  by (rewrite den_isBinOpR; destruct OP as [| [| [|]]]; subst; auto).
  replace
    (tc_val t (eval_binop op (typeof e1) (typeof e2) (eval_expr e1 rho) (eval_expr e2 rho)))
  with
    (tc_val t
      (force_val
        (match classify_cmp' (typeof e1) (typeof e2) with
         | cmp_case_pp => if orb (eqb_type (typeof e1) int_or_ptr_type)
                                 (eqb_type (typeof e2) int_or_ptr_type) 
            then (fun _ _ => None)
            else sem_cmp_pp (op_to_cmp op)
         | cmp_case_pl => if eqb_type (typeof e1) int_or_ptr_type
            then (fun _ _ => None)
            else sem_cmp_pl (op_to_cmp op)
         | cmp_case_lp => if eqb_type (typeof e2) int_or_ptr_type
            then (fun _ _ => None)
            else sem_cmp_lp (op_to_cmp op)
         | cmp_default => sem_cmp_default (op_to_cmp op) (typeof e1) (typeof e2)
         end (eval_expr e1 rho) (eval_expr e2 rho))))
  by (destruct OP as [| [| [|]]]; subst; rewrite <- classify_cmp_eq; auto).
  unfold tc_int_or_ptr_type in IBR.
    replace (check_pp_int' e1 e2 op t (Ebinop op e1 e2 t))
    with (tc_andp' (tc_test_order' e1 e2)
                   (tc_bool (is_int_type t) (op_result_type (Ebinop op e1 e2 t))))
    in IBR
    by (unfold check_pp_int'; destruct OP as [| [| [|]]]; subst; auto).
    replace (check_pp_int' e1 (Ecast e2 (Tint I32 Unsigned noattr)) op t (Ebinop op e1 e2 t))
    with (tc_andp' (tc_test_order' e1 (Ecast e2 (Tint I32 Unsigned noattr)))
                   (tc_bool (is_int_type t) (op_result_type (Ebinop op e1 e2 t))))
    in IBR
    by (unfold check_pp_int'; destruct OP as [| [| [|]]]; subst; auto).
    replace (check_pp_int' (Ecast e1 (Tint I32 Unsigned noattr)) e2 op t (Ebinop op e1 e2 t))
    with (tc_andp' (tc_test_order' (Ecast e1 (Tint I32 Unsigned noattr)) e2)
                   (tc_bool (is_int_type t) (op_result_type (Ebinop op e1 e2 t))))
    in IBR
    by (unfold check_pp_int'; destruct OP as [| [| [|]]]; subst; auto).
  destruct (classify_cmp' (typeof e1) (typeof e2)) eqn:?H; try solve [inv IBR].
1,2,3:  
    simpl in IBR; unfold_lift in IBR;
    repeat match goal with
    | H: _ /\ _ |- _ => destruct H
    | H: app_pred (denote_tc_assert (tc_bool _ _) _) _ |- _ => 
                      apply tc_bool_e in H
    | H: negb (eqb_type ?A ?B) = true |- _ =>
             let J := fresh "J" in
              destruct (eqb_type A B) eqn:J; [inv H | clear H]              
    end;
    rewrite tc_val_tc_val_PM in TV1,TV2;
    destruct (typeof e1) as [| [| | |] [|] | | | | | | |];
    destruct (typeof e2) as [| [| | |] [|] | | | | | | |];
    simpl in H; inv H;
    inv TV1; inv TV2;
    try (rewrite J in *; clear J);
    try (rewrite J0 in *; clear J0);
    destruct (eval_expr e1 rho), (eval_expr e2 rho);
    simpl in *; try contradiction;
    repeat match goal with H: _ /\ _ |- _ => destruct H end;
    subst;
    destruct t as [| [| | |] [|] | | | | | | |];
    try solve [inv H2];
    try apply tc_val_of_bool;
    try solve [apply sem_cmp_pp_ip; auto; destruct OP as [| [| [|]]]; subst; auto];
    try solve [apply sem_cmp_pp_pi; auto; destruct OP as [| [| [|]]]; subst; auto];
    try solve [apply sem_cmp_pp_pp; auto; destruct OP as [| [| [|]]]; subst; auto];
    try solve [eapply sem_cmp_pp_pp'; eauto; destruct OP as [| [| [|]]]; subst; auto].

    unfold sem_cmp_default.
    apply tc_bool_e in IBR.
    rewrite !andb_true_iff in IBR.
    destruct IBR as [[?IBR ?IBR] ?IBR].
    apply tc_val_sem_cmp_binarith'; auto.
Qed.

Lemma typecheck_binop_sound:
forall op {CS: compspecs} (rho : environ) m (e1 e2 : expr) (t : type)
   (IBR: denote_tc_assert (isBinOpResultType op e1 e2 t) rho m)
   (TV2: tc_val (typeof e2) (eval_expr e2 rho))
   (TV1: tc_val (typeof e1) (eval_expr e1 rho)),
   tc_val t
     (eval_binop op (typeof e1) (typeof e2) (eval_expr e1 rho) (eval_expr e2 rho)).
Proof.
  intros.
  destruct op;
  first
    [ eapply typecheck_Oadd_sound; eauto
    | eapply typecheck_Osub_sound; eauto
    | eapply typecheck_Omul_sound; eauto
    | eapply typecheck_Odiv_sound; eauto
    | eapply typecheck_Omod_sound; eauto
    | eapply typecheck_Oshift_sound; solve [eauto]
    | eapply typecheck_Obin_sound; solve [eauto]
    | eapply typecheck_Otest_eq_sound; solve [eauto]
    | eapply typecheck_Otest_order_sound; solve [eauto]].
Qed.

