Require Import VST.msl.predicates_hered.
Require Import VST.veric.ghosts.
Require Import VST.veric.invariants.
Require Import VST.msl.iter_sepcon.
Require Import VST.msl.ageable.
Require Import VST.msl.age_sepalg.
From VST.floyd Require Import base2 client_lemmas data_at_rec_lemmas
   field_at reptype_lemmas mapsto_memory_block aggregate_pred
   nested_field_lemmas call_lemmas entailer.
Require Import VST.zlist.sublist.
Import FashNotation.
Import LiftNotation ListNotations.
Import compcert.lib.Maps.

(* general list lemmas *)
Notation vint z := (Vint (Int.repr z)).
Notation vptrofs z := (Vptrofs (Ptrofs.repr z)).

Open Scope logic.

Lemma mapsto_value_eq: forall sh1 sh2 t p v1 v2, readable_share sh1 -> readable_share sh2 ->
  v1 <> Vundef -> v2 <> Vundef -> mapsto sh1 t p v1 * mapsto sh2 t p v2 |-- !!(v1 = v2).
Proof.
  intros; unfold mapsto.
  destruct (access_mode t); try solve [entailer!].
  destruct (type_is_volatile t); try solve [entailer!].
  destruct p; try solve [entailer!].
  destruct (readable_share_dec sh1); [|contradiction n; auto].
  destruct (readable_share_dec sh2); [|contradiction n; auto].

  Transparent mpred.
  rewrite !prop_false_andp with (P := v1 = Vundef), !orp_FF; auto; Intros.
  rewrite !prop_false_andp with (P := v2 = Vundef), !orp_FF; auto; Intros.
  Opaque mpred.
  constructor; apply res_predicates.address_mapsto_value_cohere.
Qed.

Lemma mapsto_value_cohere: forall sh1 sh2 t p v1 v2, readable_share sh1 ->
  mapsto sh1 t p v1 * mapsto sh2 t p v2 |-- mapsto sh1 t p v1 * mapsto sh2 t p v1.
Proof.
  intros; unfold mapsto.
  destruct (access_mode t); try simple apply derives_refl.
  destruct (type_is_volatile t); try simple apply derives_refl.
  destruct p; try simple apply derives_refl.
  destruct (readable_share_dec sh1); [|contradiction n; auto].
  destruct (eq_dec v1 Vundef).
  Transparent mpred.
  - subst; rewrite !prop_false_andp with (P := tc_val t Vundef), !FF_orp, prop_true_andp; auto;
      try apply tc_val_Vundef.
    cancel.
    rewrite prop_true_andp with (P := Vundef = Vundef); auto.
    if_tac.
    + apply orp_left; Intros; auto.
      Exists v2; auto.
    + Intros. apply andp_right; auto. apply prop_right; split; auto. hnf; intros. contradiction H3; auto.
  - rewrite !prop_false_andp with (P := v1 = Vundef), !orp_FF; auto; Intros.
    apply andp_right; [apply prop_right; auto|].
    if_tac.
    eapply derives_trans with (Q := _ * EX v2' : val,
      res_predicates.address_mapsto m v2' _ _);
      [apply sepcon_derives; [apply derives_refl|]|].
    + destruct (eq_dec v2 Vundef).
      * subst; rewrite prop_false_andp with (P := tc_val t Vundef), FF_orp;
          try apply tc_val_Vundef.
        rewrite prop_true_andp with (P := Vundef = Vundef); auto.  apply derives_refl.
      * rewrite prop_false_andp with (P := v2 = Vundef), orp_FF; auto; Intros.
        Exists v2; auto.
    + Intro v2'.
      assert_PROP (v1 = v2') by (constructor; apply res_predicates.address_mapsto_value_cohere).
      subst. apply sepcon_derives; auto. apply andp_right; auto.
      apply prop_right; auto.
    + apply sepcon_derives; auto.
      Intros. apply andp_right; auto.
      apply prop_right; split; auto.
      intro; auto.
Opaque mpred.
Qed.

Lemma data_at_value_cohere : forall {cs : compspecs} sh1 sh2 t v1 v2 p, readable_share sh1 ->
  type_is_by_value t = true -> type_is_volatile t = false ->
  data_at sh1 t v1 p * data_at sh2 t v2 p |--
  data_at sh1 t v1 p * data_at sh2 t v1 p.
Proof.
  intros; unfold data_at, field_at, at_offset; Intros.
  apply andp_right; [apply prop_right; auto|].
  rewrite !by_value_data_at_rec_nonvolatile by auto.
  apply mapsto_value_cohere; auto.
Qed.

Lemma data_at_value_eq : forall {cs : compspecs} sh1 sh2 t v1 v2 p,
  readable_share sh1 -> readable_share sh2 ->
  is_pointer_or_null v1 -> is_pointer_or_null v2 ->
  data_at sh1 (tptr t) v1 p * data_at sh2 (tptr t) v2 p |-- !! (v1 = v2).
Proof.
  intros; unfold data_at, field_at, at_offset; Intros.
  rewrite !by_value_data_at_rec_nonvolatile by auto.
  apply mapsto_value_eq; auto.
  { intros X; subst; contradiction. }
  { intros X; subst; contradiction. }
Qed.

Lemma data_at_array_value_cohere : forall {cs : compspecs} sh1 sh2 t z a v1 v2 p, readable_share sh1 ->
  type_is_by_value t = true -> type_is_volatile t = false ->
  data_at sh1 (Tarray t z a) v1 p * data_at sh2 (Tarray t z a) v2 p |--
  data_at sh1 (Tarray t z a) v1 p * data_at sh2 (Tarray t z a) v1 p.
Proof.
  intros; unfold data_at, field_at, at_offset; Intros.
  apply andp_right; [apply prop_right; auto|].
  rewrite !data_at_rec_eq; simpl.
  unfold aggregate_pred.array_pred, array_pred; Intros.
  apply andp_right; [apply prop_right; auto|].
  rewrite Z.sub_0_r in *.
  erewrite aggregate_pred.rangespec_ext by (intros; rewrite Z.sub_0_r; apply f_equal; auto).
  setoid_rewrite aggregate_pred.rangespec_ext at 2; [|intros; rewrite Z.sub_0_r; apply f_equal; auto].
  setoid_rewrite aggregate_pred.rangespec_ext at 4; [|intros; rewrite Z.sub_0_r; apply f_equal; auto].
  clear H3 H4.
  rewrite Z2Nat_max0 in *.
  forget (offset_val 0 p) as p'; forget (Z.to_nat z) as n; forget 0 as lo; revert dependent lo; induction n; auto; simpl; intros.
 apply derives_refl.
  match goal with |- (?P1 * ?Q1) * (?P2 * ?Q2) |-- _ =>
    eapply derives_trans with (Q := (P1 * P2) * (Q1 * Q2)); [cancel|] end.
  eapply derives_trans; [apply sepcon_derives|].
  - unfold at_offset.
    rewrite 2by_value_data_at_rec_nonvolatile by auto.
    apply mapsto_value_cohere; auto.
  - apply IHn.
  - unfold at_offset; rewrite 2by_value_data_at_rec_nonvolatile by auto; cancel.
Qed.

Lemma extract_nth_sepcon : forall l i, 0 <= i < Zlength l ->
  fold_right sepcon emp l = Znth i l * fold_right sepcon emp (upd_Znth i l emp).
Proof.
  intros.
  erewrite <- sublist_same with (al := l) at 1; auto.
  rewrite sublist_split with (mid := i); try lia.
  rewrite (sublist_next i); try lia.
  rewrite sepcon_app; simpl.
  rewrite <- sepcon_assoc, (sepcon_comm _ (Znth i l)).
  unfold_upd_Znth_old; rewrite sepcon_app, sepcon_assoc; simpl.
  rewrite emp_sepcon; auto.
Qed.

Lemma replace_nth_sepcon : forall P l i, 0 <= i < Zlength l ->
  P * fold_right sepcon emp (upd_Znth i l emp) =
    fold_right sepcon emp (upd_Znth i l P).
Proof.
  intros; unfold_upd_Znth_old.
  rewrite !sepcon_app; simpl.
  rewrite emp_sepcon, <- !sepcon_assoc, (sepcon_comm P); auto.
Qed.

Lemma sepcon_derives_prop : forall P Q R, (P |-- !!R) -> P * Q |-- !!R.
Proof.
  intros; eapply derives_trans; [apply saturate_aux20 with (Q' := True);[eauto|]|].
  - entailer!.
  - apply prop_left; intros (? & ?); apply prop_right; auto.
Qed.

Lemma sepcon_map : forall {A} P Q (l : list A), fold_right sepcon emp (map (fun x => P x * Q x) l) =
  fold_right sepcon emp (map P l) * fold_right sepcon emp (map Q l).
Proof.
  induction l; simpl.
  - rewrite sepcon_emp; auto.
  - rewrite !sepcon_assoc, <- (sepcon_assoc (fold_right _ _ _) (Q a)), (sepcon_comm (fold_right _ _ _) (Q _)).
    rewrite IHl; rewrite sepcon_assoc; auto.
Qed.

Lemma sepcon_list_derives : forall l1 l2 (Hlen : Zlength l1 = Zlength l2)
  (Heq : forall i, 0 <= i < Zlength l1 -> Znth i l1 |-- Znth i l2),
  fold_right sepcon emp l1 |-- fold_right sepcon emp l2.
Proof.
  induction l1; destruct l2; auto; simpl; intros; rewrite ?Zlength_nil, ?Zlength_cons in *;
    try (rewrite Zlength_correct in *; lia).
  apply sepcon_derives.
  - specialize (Heq 0); rewrite !Znth_0_cons in Heq; apply Heq.
    rewrite Zlength_correct; lia.
  - apply IHl1; [lia|].
    intros; specialize (Heq (i + 1)); rewrite !Znth_pos_cons, !Z.add_simpl_r in Heq; try lia.
    apply Heq; lia.
Qed.

Lemma sepcon_rotate : forall lP m n, 0 <= n - m < Zlength lP ->
  fold_right sepcon emp lP = fold_right sepcon emp (rotate lP m n).
Proof.
  intros.
  unfold rotate.
  rewrite sepcon_app, sepcon_comm, <- sepcon_app, sublist_rejoin, sublist_same by lia; auto.
Qed.

Lemma sepcon_In : forall l P, In P l -> exists Q, fold_right sepcon emp l = P * Q.
Proof.
  induction l; [contradiction|].
  intros ? [|]; simpl; subst; eauto.
  destruct (IHl _ H) as [? ->].
  rewrite sepcon_comm, sepcon_assoc; eauto.
Qed.

Lemma extract_wand_sepcon : forall l P, In P l ->
  fold_right sepcon emp l = P * (P -* fold_right sepcon emp l).
Proof.
  intros.
  destruct (sepcon_In _ _ H).
  eapply wand_eq; eauto.
Qed.

Lemma wand_sepcon_map : forall {A} (R : A -> mpred) l P Q
  (HR : forall i, In i l -> R i = P i * Q i),
  fold_right sepcon emp (map R l) = fold_right sepcon emp (map P l) *
    (fold_right sepcon emp (map P l) -* fold_right sepcon emp (map R l)).
Proof.
  intros; eapply wand_eq.
  erewrite map_ext_in, sepcon_map; eauto.
  apply HR.
Qed.

Lemma semax_extract_later_prop'':
  forall {CS : compspecs} {Espec: OracleKind},
    forall (Delta : tycontext) (PP : Prop) P Q R c post P1 P2,
      (P2 |-- !!PP) ->
      (PP -> semax Delta (PROPx P (LOCALx Q (SEPx (P1 && |>P2 :: R)))) c post) ->
      semax Delta (PROPx P (LOCALx Q (SEPx (P1 && |>P2 :: R)))) c post.
Proof.
  intros.
  erewrite (add_andp P2) by eauto.
  apply semax_pre0 with (P' := |>!!PP && PROPx P (LOCALx Q (SEPx (P1 && |>P2 :: R)))).
  { go_lowerx.
    rewrite later_andp, <- andp_assoc, andp_comm, corable_andp_sepcon1; auto.
    apply corable_later; auto. }
  apply semax_extract_later_prop; auto.
Qed.

Lemma field_at_array_inbounds : forall {cs : compspecs} sh t z a i v p,
  field_at sh (Tarray t z a) [ArraySubsc i] v p |-- !!(0 <= i < z).
Proof.
  intros; entailer!.
  destruct H as (_ & _ & _ & _ & _ & ?); auto.
Qed.

Lemma valid_pointer_isptr : forall v, valid_pointer v |-- !!(is_pointer_or_null v).
Proof.
Transparent mpred.
Transparent predicates_hered.pred.
  destruct v; simpl; try apply derives_refl.
  apply prop_right; auto.
Opaque mpred. Opaque predicates_hered.pred.
Qed.

#[export] Hint Resolve valid_pointer_isptr : saturate_local.

Lemma approx_imp : forall n P Q, compcert_rmaps.RML.R.approx n (predicates_hered.imp P Q) =
  compcert_rmaps.RML.R.approx n (predicates_hered.imp (compcert_rmaps.RML.R.approx n P)
    (compcert_rmaps.RML.R.approx n Q)).
Proof.
  intros; apply predicates_hered.pred_ext; intros ? (? & Himp); split; auto; intros ? ? Ha' Hext HP.
  - destruct HP; split; eauto.
  - eapply Himp; eauto; split; auto.
    pose proof (ageable.necR_level _ _ Ha'); apply ext_level in Hext; lia.
Qed.

Definition super_non_expansive' {A} P := forall n ts x, compcert_rmaps.RML.R.approx n (P ts x) =
  compcert_rmaps.RML.R.approx n (P ts (functors.MixVariantFunctor.fmap (rmaps.dependent_type_functor_rec ts A)
        (compcert_rmaps.RML.R.approx n) (compcert_rmaps.RML.R.approx n) x)).

Lemma approx_0 : forall P, compcert_rmaps.RML.R.approx 0 P = FF.
Proof.
  intros; apply predicates_hered.pred_ext.
  - intros ? []; lia.
  - intros ??; contradiction.
Qed.

Lemma approx_eq : forall n (P : mpred) r, app_pred (compcert_rmaps.RML.R.approx n P) r = (if lt_dec (level r) n then app_pred P r else False).
Proof.
  intros; apply prop_ext; split.
  - intros []; if_tac; auto.
  - if_tac; split; auto; lia.
Qed.

Lemma approx_iter_sepcon' : forall {B} n f (lP : list B) P,
  compcert_rmaps.RML.R.approx n (iter_sepcon f lP)  * compcert_rmaps.RML.R.approx n P =
  iter_sepcon (compcert_rmaps.RML.R.approx n oo f) lP * compcert_rmaps.RML.R.approx n P.
Proof.
  induction lP; simpl; intros.
  - apply predicates_hered.pred_ext; intros ? (? & ? & ? & ? & ?).
    + destruct H0; do 3 eexists; eauto.
    + do 3 eexists; eauto; split; auto; split; auto.
      destruct H1; apply join_level in H as []; lia.
  - rewrite approx_sepcon, !sepcon_assoc, IHlP; auto.
Qed.

Corollary approx_iter_sepcon: forall {B} n f (lP : list B), lP <> [] ->
  compcert_rmaps.RML.R.approx n (iter_sepcon f lP) =
  iter_sepcon (compcert_rmaps.RML.R.approx n oo f) lP.
Proof.
  destruct lP; [contradiction | simpl].
  intros; rewrite approx_sepcon, !(sepcon_comm (compcert_rmaps.RML.R.approx n (f b))), approx_iter_sepcon'; auto.
Qed.

Lemma approx_FF : forall n, compcert_rmaps.RML.R.approx n FF = FF.
Proof.
  intro; apply predicates_hered.pred_ext; intros ??; try contradiction.
  destruct H; contradiction.
Qed.

Lemma later_nonexpansive' : nonexpansive (@later mpred _ _).
Proof.
  apply contractive_nonexpansive, later_contractive.
  intros ??; auto.
Qed.

Lemma later_nonexpansive : forall n P, compcert_rmaps.RML.R.approx n (|> P)%pred =
  compcert_rmaps.RML.R.approx n (|> compcert_rmaps.RML.R.approx n P)%pred.
Proof.
  intros.
  intros; apply predicates_hered.pred_ext.
  - intros ? []; split; auto.
    intros ? Hlater; split; auto.
    apply laterR_level in Hlater; lia.
  - intros ? []; split; auto.
    intros ? Hlater.
    specialize (H0 _ Hlater) as []; auto.
Qed.

Lemma allp_nonexpansive : forall {A} n P, compcert_rmaps.RML.R.approx n (ALL y : A, P y)%pred =
  compcert_rmaps.RML.R.approx n (ALL y, compcert_rmaps.RML.R.approx n (P y))%pred.
Proof.
  intros.
  apply predicates_hered.pred_ext; intros ? [? Hall]; split; auto; intro; simpl in *.
  - split; auto.
  - apply Hall.
Qed.

Lemma fold_right_sepcon_nonexpansive : forall lP1 lP2, Zlength lP1 = Zlength lP2 ->
  (ALL i : Z, Znth i lP1 <=> Znth i lP2) |--
  fold_right sepcon emp lP1 <=> fold_right sepcon emp lP2.
Proof.
  induction lP1; intros.
  - symmetry in H; apply Zlength_nil_inv in H; subst.
    constructor. apply eqp_refl.
  - destruct lP2; [apply Zlength_nil_inv in H; discriminate|].
    rewrite !Zlength_cons in H. constructor.
    simpl fold_right; apply eqp_sepcon.
    + apply predicates_hered.allp_left with 0.
      rewrite !Znth_0_cons; auto.
    + eapply predicates_hered.derives_trans, IHlP1; [|lia].
      apply predicates_hered.allp_right; intro i.
      apply predicates_hered.allp_left with (i + 1).
      destruct (zlt i 0).
      { rewrite !(Znth_underflow _ _ l); apply eqp_refl. }
      rewrite !Znth_pos_cons, Z.add_simpl_r by lia; auto.
Qed.


(* tactics *)
Lemma void_ret : ifvoid tvoid (` (PROP ( )  LOCAL ()  SEP ()) (make_args [] []))
  (EX v : val, ` (PROP ( )  LOCAL ()  SEP ()) (make_args [ret_temp] [v])) = emp.
Proof.
  extensionality; simpl.
  unfold liftx, lift, PROPx, LOCALx, SEPx; simpl. autorewrite with norm. auto.
Qed.
