Require Import floyd.proofauto.
Import ListNotations.
Local Open Scope logic.

Require Import hmacdrbg.hmac_drbg.
Require Import hmacdrbg.HMAC_DRBG_algorithms.
Require Import hmacdrbg.spec_hmac_drbg.
Require Import sha.HMAC256_functional_prog.
Require Import sha.spec_sha.
Require Import hmacdrbg.HMAC_DRBG_common_lemmas.
 
Fixpoint HMAC_DRBG_update_round (HMAC: list Z -> list Z -> list Z) (provided_data K V: list Z) (round: nat): (list Z * list Z) :=
  match round with
    | O => (K, V)
    | S round' =>
      let (K, V) := HMAC_DRBG_update_round HMAC provided_data K V round' in
      let K := HMAC (V ++ [Z.of_nat round'] ++ provided_data) K in
      let V := HMAC V K in
      (K, V)
  end.

Definition HMAC_DRBG_update_concrete (HMAC: list Z -> list Z -> list Z) (provided_data K V: list Z): (list Z * list Z) :=
  let rounds := match provided_data with
                  | [] => 1%nat
                  | _ => 2%nat
                end in
  HMAC_DRBG_update_round HMAC provided_data K V rounds.

Theorem HMAC_DRBG_update_concrete_correct:
  forall HMAC provided_data K V, HMAC_DRBG_update HMAC provided_data K V = HMAC_DRBG_update_concrete HMAC provided_data K V.
Proof.
  intros.
  destruct provided_data; reflexivity.
Qed.

Definition update_rounds (non_empty_additional: bool): Z :=
  if non_empty_additional then 2 else 1.

Lemma HMAC_DRBG_update_round_incremental:
  forall key V initial_state_abs contents n,
    (key, V) = HMAC_DRBG_update_round HMAC256 contents
                           (hmac256drbgabs_key initial_state_abs)
                           (hmac256drbgabs_value initial_state_abs) n ->
    (HMAC256 (V ++ (Z.of_nat n) :: contents) key,
     HMAC256 V (HMAC256 (V ++ (Z.of_nat n) :: contents) key)) =
    HMAC_DRBG_update_round HMAC256 contents
                           (hmac256drbgabs_key initial_state_abs)
                           (hmac256drbgabs_value initial_state_abs) (n + 1).
Proof.
  intros.
  rewrite plus_comm.
  simpl.
  rewrite <- H.
  reflexivity.
Qed.

Lemma HMAC_DRBG_update_round_incremental_Z:
  forall key V initial_state_abs contents i,
    0 <= i ->
    (key, V) = HMAC_DRBG_update_round HMAC256 contents
                           (hmac256drbgabs_key initial_state_abs)
                           (hmac256drbgabs_value initial_state_abs) (Z.to_nat i) ->
    (HMAC256 (V ++ i :: contents) key,
     HMAC256 V (HMAC256 (V ++ i :: contents) key)) =
    HMAC_DRBG_update_round HMAC256 contents
                           (hmac256drbgabs_key initial_state_abs)
                           (hmac256drbgabs_value initial_state_abs) (Z.to_nat (i + 1)).
Proof.
  intros.
  specialize (HMAC_DRBG_update_round_incremental _ _ _ _ _ H0); intros. clear H0.
  rewrite (Z2Nat.id _ H) in H1. 
  rewrite Z2Nat.inj_add; try assumption; omega.
Qed.

Lemma loopbody: forall (Espec : OracleKind)
  (contents : list Z)
  (additional : val)
  (add_len : Z)
  (ctx IS1a IS1b IS1c : val)
  (IS2 : list val)
  (IS3 IS4 IS5 IS6 : val)
  (initial_state_abs : hmac256drbgabs)
  (kv : val)
  (info_contents : md_info_state)
  (sep K : val)
  (H : 0 <= add_len <= Int.max_unsigned)
  (initial_value : list Z)
  (Heqinitial_value : initial_value = hmac256drbgabs_value initial_state_abs)
  (H0 : Zlength initial_value = 32)
  (H1 : add_len = Zlength contents \/ add_len =0)
  (H2 : Forall general_lemmas.isbyteZ initial_value)
  (H3 : Forall general_lemmas.isbyteZ contents)
  (PNadditional : is_pointer_or_null additional)
  (Pctx : isptr ctx)
  (na : bool)
  (Heqna : na = (negb (eq_dec additional nullval) && negb (eq_dec add_len 0))%bool)
  (rounds : Z)
  (Heqrounds : rounds = (if na then 2 else 1))
  (initial_key : list Z)
  (Heqinitial_key : initial_key = hmac256drbgabs_key initial_state_abs)
  (i : Z)
  (H4 : 0 <= i < rounds)
  (key value : list Z)
  (state_abs : hmac256drbgabs)
  (H5 : (key, value) =
       HMAC_DRBG_update_round HMAC256 (if na then contents else []) initial_key initial_value
       (Z.to_nat i))
  (H6 : key = hmac256drbgabs_key state_abs)
  (H7 : value = hmac256drbgabs_value state_abs)
  (H8 : hmac256drbgabs_metadata_same state_abs initial_state_abs)
  (H9 : Zlength value = Z.of_nat SHA256.DigestLength)
  (H10 : Forall general_lemmas.isbyteZ value),
@semax hmac_drbg_compspecs.CompSpecs Espec 
  (initialized_list
     [_info; _md_len; _rounds; _sep_value; _t'3; _t'2; _t'1]
     (func_tycontext f_mbedtls_hmac_drbg_update HmacDrbgVarSpecs
        HmacDrbgFunSpecs))
  (PROP ( )
   LOCAL (temp _sep_value (Vint (Int.repr i)); temp _rounds (Vint (Int.repr rounds));
   temp _md_len (Vint (Int.repr 32)); temp _ctx ctx; lvar _K (tarray tuchar 32) K;
   lvar _sep (tarray tuchar 1) sep; temp _additional additional;
   temp _add_len (Vint (Int.repr add_len)); gvar sha._K256 kv)
   SEP (hmac256drbgabs_common_mpreds state_abs
          (IS1a, (IS1b, IS1c), (IS2, (IS3, (IS4, (IS5, IS6))))) ctx info_contents;
   @data_at_ hmac_drbg_compspecs.CompSpecs Tsh (tarray tuchar 32) K;
   da_emp Tsh (tarray tuchar (Zlength contents)) (@map int val Vint (@map Z int Int.repr contents))
     additional; @data_at_ hmac_drbg_compspecs.CompSpecs Tsh (tarray tuchar 1) sep;
   K_vector kv))
  (Ssequence
     (Sassign
        (Ederef
           (Ebinop Oadd (Evar _sep (tarray tuchar 1)) (Econst_int (Int.repr 0) tint)
              (tptr tuchar)) tuchar) (Etempvar _sep_value tint))
     (Ssequence
        (Scall (@None ident)
           (Evar _mbedtls_md_hmac_reset
              (Tfunction (Tcons (tptr (Tstruct _mbedtls_md_context_t noattr)) Tnil) tint
                 cc_default))
           [Eaddrof
              (Efield
                 (Ederef (Etempvar _ctx (tptr (Tstruct _mbedtls_hmac_drbg_context noattr)))
                    (Tstruct _mbedtls_hmac_drbg_context noattr)) _md_ctx
                 (Tstruct _mbedtls_md_context_t noattr))
              (tptr (Tstruct _mbedtls_md_context_t noattr))])
        (Ssequence
           (Scall (@None ident)
              (Evar _mbedtls_md_hmac_update
                 (Tfunction
                    (Tcons (tptr (Tstruct _mbedtls_md_context_t noattr))
                       (Tcons (tptr tuchar) (Tcons tuint Tnil))) tint cc_default))
              [Eaddrof
                 (Efield
                    (Ederef
                       (Etempvar _ctx (tptr (Tstruct _mbedtls_hmac_drbg_context noattr)))
                       (Tstruct _mbedtls_hmac_drbg_context noattr)) _md_ctx
                    (Tstruct _mbedtls_md_context_t noattr))
                 (tptr (Tstruct _mbedtls_md_context_t noattr));
              Efield
                (Ederef (Etempvar _ctx (tptr (Tstruct _mbedtls_hmac_drbg_context noattr)))
                   (Tstruct _mbedtls_hmac_drbg_context noattr)) _V 
                (tarray tuchar 32); Etempvar _md_len tuint])
           (Ssequence
              (Scall (@None ident)
                 (Evar _mbedtls_md_hmac_update
                    (Tfunction
                       (Tcons (tptr (Tstruct _mbedtls_md_context_t noattr))
                          (Tcons (tptr tuchar) (Tcons tuint Tnil))) tint cc_default))
                 [Eaddrof
                    (Efield
                       (Ederef
                          (Etempvar _ctx (tptr (Tstruct _mbedtls_hmac_drbg_context noattr)))
                          (Tstruct _mbedtls_hmac_drbg_context noattr)) _md_ctx
                       (Tstruct _mbedtls_md_context_t noattr))
                    (tptr (Tstruct _mbedtls_md_context_t noattr));
                 Evar _sep (tarray tuchar 1); Econst_int (Int.repr 1) tint])
              (Ssequence
                 (Sifthenelse
                    (Ebinop Oeq (Etempvar _rounds tint) (Econst_int (Int.repr 2) tint) tint)
                    (Scall (@None ident)
                       (Evar _mbedtls_md_hmac_update
                          (Tfunction
                             (Tcons (tptr (Tstruct _mbedtls_md_context_t noattr))
                                (Tcons (tptr tuchar) (Tcons tuint Tnil))) tint cc_default))
                       [Eaddrof
                          (Efield
                             (Ederef
                                (Etempvar _ctx
                                   (tptr (Tstruct _mbedtls_hmac_drbg_context noattr)))
                                (Tstruct _mbedtls_hmac_drbg_context noattr)) _md_ctx
                             (Tstruct _mbedtls_md_context_t noattr))
                          (tptr (Tstruct _mbedtls_md_context_t noattr));
                       Etempvar _additional (tptr tuchar); Etempvar _add_len tuint]) Sskip)
                 (Ssequence
                    (Scall (@None ident)
                       (Evar _mbedtls_md_hmac_finish
                          (Tfunction
                             (Tcons (tptr (Tstruct _mbedtls_md_context_t noattr))
                                (Tcons (tptr tuchar) Tnil)) tint cc_default))
                       [Eaddrof
                          (Efield
                             (Ederef
                                (Etempvar _ctx
                                   (tptr (Tstruct _mbedtls_hmac_drbg_context noattr)))
                                (Tstruct _mbedtls_hmac_drbg_context noattr)) _md_ctx
                             (Tstruct _mbedtls_md_context_t noattr))
                          (tptr (Tstruct _mbedtls_md_context_t noattr));
                       Evar _K (tarray tuchar 32)])
                    (Ssequence
                       (Scall (@None ident)
                          (Evar _mbedtls_md_hmac_starts
                             (Tfunction
                                (Tcons (tptr (Tstruct _mbedtls_md_context_t noattr))
                                   (Tcons (tptr tuchar) (Tcons tuint Tnil))) tint
                                cc_default))
                          [Eaddrof
                             (Efield
                                (Ederef
                                   (Etempvar _ctx
                                      (tptr (Tstruct _mbedtls_hmac_drbg_context noattr)))
                                   (Tstruct _mbedtls_hmac_drbg_context noattr)) _md_ctx
                                (Tstruct _mbedtls_md_context_t noattr))
                             (tptr (Tstruct _mbedtls_md_context_t noattr));
                          Evar _K (tarray tuchar 32); Etempvar _md_len tuint])
                       (Ssequence
                          (Scall (@None ident)
                             (Evar _mbedtls_md_hmac_update
                                (Tfunction
                                   (Tcons (tptr (Tstruct _mbedtls_md_context_t noattr))
                                      (Tcons (tptr tuchar) (Tcons tuint Tnil))) tint
                                   cc_default))
                             [Eaddrof
                                (Efield
                                   (Ederef
                                      (Etempvar _ctx
                                         (tptr (Tstruct _mbedtls_hmac_drbg_context noattr)))
                                      (Tstruct _mbedtls_hmac_drbg_context noattr)) _md_ctx
                                   (Tstruct _mbedtls_md_context_t noattr))
                                (tptr (Tstruct _mbedtls_md_context_t noattr));
                             Efield
                               (Ederef
                                  (Etempvar _ctx
                                     (tptr (Tstruct _mbedtls_hmac_drbg_context noattr)))
                                  (Tstruct _mbedtls_hmac_drbg_context noattr)) _V
                               (tarray tuchar 32); Etempvar _md_len tuint])
                          (Scall (@None ident)
                             (Evar _mbedtls_md_hmac_finish
                                (Tfunction
                                   (Tcons (tptr (Tstruct _mbedtls_md_context_t noattr))
                                      (Tcons (tptr tuchar) Tnil)) tint cc_default))
                             [Eaddrof
                                (Efield
                                   (Ederef
                                      (Etempvar _ctx
                                         (tptr (Tstruct _mbedtls_hmac_drbg_context noattr)))
                                      (Tstruct _mbedtls_hmac_drbg_context noattr)) _md_ctx
                                   (Tstruct _mbedtls_md_context_t noattr))
                                (tptr (Tstruct _mbedtls_md_context_t noattr));
                             Efield
                               (Ederef
                                  (Etempvar _ctx
                                     (tptr (Tstruct _mbedtls_hmac_drbg_context noattr)))
                                  (Tstruct _mbedtls_hmac_drbg_context noattr)) _V
                               (tarray tuchar 32)])))))))))
  (normal_ret_assert
     (local
        (` (@eq val (Vint (Int.repr rounds)))
           (@eval_expr hmac_drbg_compspecs.CompSpecs (Etempvar _rounds tint))) &&
      PROP (0 <= i + 1 <= rounds)
      LOCAL (temp _sep_value (Vint (Int.repr i)); temp _rounds (Vint (Int.repr rounds));
      temp _md_len (Vint (Int.repr 32)); temp _ctx ctx; lvar _K (tarray tuchar 32) K;
      lvar _sep (tarray tuchar 1) sep; temp _additional additional;
      temp _add_len (Vint (Int.repr add_len)); gvar sha._K256 kv)
      SEP (EX key0 : list Z,
           (EX value0 : list Z,
            (EX final_state_abs : hmac256drbgabs,
             !! ((key0, value0) =
                 HMAC_DRBG_update_round HMAC256 (if na then contents else []) initial_key
                   initial_value (Z.to_nat (i + 1)) /\
                 key0 = hmac256drbgabs_key final_state_abs /\
                 value0 = hmac256drbgabs_value final_state_abs /\
                 hmac256drbgabs_metadata_same final_state_abs initial_state_abs /\
                 @Zlength Z value0 = Z.of_nat SHA256.DigestLength /\
                 @Forall Z general_lemmas.isbyteZ value0) &&
             hmac256drbgabs_common_mpreds final_state_abs
               (IS1a, (IS1b, IS1c), (IS2, (IS3, (IS4, (IS5, IS6))))) ctx info_contents));
      @data_at_ hmac_drbg_compspecs.CompSpecs Tsh (tarray tuchar 32) K;
      da_emp Tsh (tarray tuchar (Zlength contents)) (@map int val Vint (@map Z int Int.repr contents))
        additional; @data_at_ hmac_drbg_compspecs.CompSpecs Tsh (tarray tuchar 1) sep;
      K_vector kv))).
Proof. intros. simpl.
    unfold hmac256drbgabs_common_mpreds. repeat flatten_sepcon_in_SEP. 
    (*unfold hmac256drbgabs_to_state. simpl.*)
    unfold hmac256drbgabs_to_state. simpl. destruct state_abs. simpl in *. subst key0 value.
    abbreviate_semax. Intros. 
    freeze [1;2;3;5;6] FR0.
    rewrite data_at_isptr with (p:= ctx).
    rewrite da_emp_isptrornull. normalize.
    unfold_data_at 1%nat. thaw FR0.
    freeze [7;8;9;10] OtherFields.
    rewrite (field_at_data_at _ _ [StructField _md_ctx]); simpl.
    rewrite (field_at_data_at _ _ [StructField _V]); simpl.

    freeze [0;1;2;3;4;5;8] FR1.
    assert_PROP (field_compatible t_struct_hmac256drbg_context_st [StructField _md_ctx] ctx) as FC_ctx_MDCTX by entailer!.
    assert (FA_ctx_MDCTX: field_address t_struct_hmac256drbg_context_st [StructField _md_ctx] ctx = ctx).
    { unfold field_address.
      destruct (field_compatible_dec t_struct_hmac256drbg_context_st); [|contradiction].
      simpl. rewrite offset_val_force_ptr. destruct ctx; try contradiction. reflexivity.
    }
    assert_PROP (field_compatible t_struct_hmac256drbg_context_st [StructField _V] ctx) as FC_ctx_V by entailer!.
    assert (FA_ctx_V: field_address t_struct_hmac256drbg_context_st [StructField _V] ctx = offset_val 12 ctx).
    { unfold field_address.
      destruct (field_compatible_dec t_struct_hmac256drbg_context_st); [|contradiction].
      reflexivity.
    }(*
    assert (Hfield_md_ctx: forall ctx', isptr ctx' -> 
        field_compatible t_struct_hmac256drbg_context_st [StructField _md_ctx] ctx' -> 
         ctx' = field_address t_struct_hmac256drbg_context_st [StructField _md_ctx] ctx').
    {
      intros ctx'' Hisptr Hfc.
      unfold field_address.
      destruct (field_compatible_dec t_struct_hmac256drbg_context_st); [|contradiction].
      simpl. change (Int.repr 0) with Int.zero. rewrite offset_val_force_ptr.
      destruct ctx''; inversion Hisptr. reflexivity.
    }
    assert (Hfield_V: forall ctx', isptr ctx' -> 
             field_compatible t_struct_hmac256drbg_context_st [StructField _V] ctx' ->
             offset_val 12 ctx' = field_address t_struct_hmac256drbg_context_st [StructField _V] ctx').
    {
      intros ctx'' Hisptr Hfc.
      unfold field_address.
      destruct (field_compatible_dec t_struct_hmac256drbg_context_st); [reflexivity|contradiction].
    }*)
    thaw FR1.
(*    destruct state_abs.*)
(*    destruct initial_state as [md_ctx [V' [reseed_counter' [entropy_len' [prediction_resistance' reseed_interval']]]]].*)
    (*rewrite <- HeqIS in *; simpl in *. subst key0 value.*)
    unfold hmac256drbg_relate. unfold md_full.
(*    assert (Hmdlen_V: md_len = Vint (Int.repr (Zlength V))).
    { rewrite H9; trivial. }*)

    (* sep[0] = sep_value; *)
    freeze [0;1;2;3;5;6;7;8] FR2.
    forward.
    thaw FR2. freeze [0;1;3;5;7;8] FR3. 

    (* mbedtls_md_hmac_reset( &ctx->md_ctx ); *)
    Time forward_call (field_address t_struct_hmac256drbg_context_st [StructField _md_ctx] ctx, 
                       (*md_ctx*)(IS1a, (IS1b, IS1c)), key, kv). (*LENB: 8secs Naphat's measure: 79 *)
    (*{
      entailer!.
    }*)
(*    Intros. v; subst v.*)

    (* mbedtls_md_hmac_update( &ctx->md_ctx, ctx->V, md_len ); *)
    thaw FR3. rewrite <- H9. freeze [3;4;5;6;8] FR4.
    Time forward_call (key, field_address t_struct_hmac256drbg_context_st [StructField _md_ctx] ctx,
                       (*md_ctx*)(IS1a, (IS1b, IS1c)),
                       field_address t_struct_hmac256drbg_context_st [StructField _V] ctx, 
                       @nil Z, V, kv). (*LENB: 8, Naphat: 83 *)
    (*{
      entailer!.
      rewrite H9; reflexivity.
    }*)
    (*{
      rewrite H9.
      change (Z.of_nat SHA256.DigestLength) with 32.
      cancel.
    }*)
    {
      rewrite H9.
      repeat split; [hnf;auto | hnf;auto | assumption].
    }
    Intros. (*Intros v; subst v.*)
      
(*    unfold upd_Znth.
    unfold sublist. *)
    simpl. 
    assert (Hiuchar: Int.zero_ext 8 (Int.repr i) = Int.repr i).
    {
      clear - H4 Heqrounds. destruct na; subst;
      apply zero_ext_inrange;
      rewrite hmac_pure_lemmas.unsigned_repr_isbyte by (hnf; omega); simpl; omega.
    }
    (*rewrite Hiuchar.*)

    (* mbedtls_md_hmac_update( &ctx->md_ctx, sep, 1 ); *)
    thaw FR4. (*rewrite Hiuchar; clear Hiuchar.*) freeze [2;4;5;6;7] FR5.
    unfold upd_Znth, sublist. simpl. rewrite Hiuchar; clear Hiuchar.
    Time forward_call (key, field_address t_struct_hmac256drbg_context_st [StructField _md_ctx] ctx,
                       (*md_ctx*)(IS1a, (IS1b, IS1c)), sep, V, [i], kv). (*LENB: 8, Naphat: 62 *)
    (*{
      entailer!.
    }
    { (*LENB: this SC is now now discharged manually*)
      unfold upd_Znth, sublist. simpl.  
      change (Zlength [i]) with 1. rewrite Hiuchar. cancel. 
    }*)
    { 
      (* prove the PROP clauses *)
      rewrite H9.
      change (Zlength [i]) with 1.
      repeat split; [hnf;auto | hnf;auto | ].
      unfold general_lemmas.isbyteZ.
      repeat constructor.
      omega.
      destruct na; subst rounds; omega.
    }
    Intros. (*Intros v; subst v.*)
      
    (* if( rounds == 2 ) *)
     thaw FR5. 
     freeze [2;4;5;6;7] FR6. 
     (*assert (NA:non_empty_additional =andb (negb (eq_dec additional nullval)) (negb (eq_dec add_len 0))).
     { clear - Heqnon_empty_additional PNadditional.
       subst. destruct additional; simpl in PNadditional; try contradiction.
       subst. destruct (initial_world.EqDec_Z add_len 0); trivial.
       destruct (initial_world.EqDec_Z add_len 0); subst; simpl; trivial.
       destruct (initial_world.EqDec_Z add_len 0); simpl; trivial. omega.
     }*)

     Time forward_if (PROP  ()
      LOCAL  (temp _sep_value (Vint (Int.repr i));
      temp _rounds (Vint (Int.repr rounds));  temp _md_len (Vint (Int.repr 32));
      temp _ctx ctx; lvar _K (tarray tuchar (Zlength V)) K;
      lvar _sep (tarray tuchar 1) sep; temp _additional additional;
      temp _add_len (Vint (Int.repr add_len)); gvar sha._K256 kv)
      SEP  (md_relate (UNDER_SPEC.hABS key (V ++ [i] ++ (if na then contents else nil))) (*md_ctx*)(IS1a, (IS1b, IS1c));
      (data_at Tsh t_struct_md_ctx_st (*md_ctx*)(IS1a, (IS1b, IS1c))
          (field_address t_struct_hmac256drbg_context_st
             [StructField _md_ctx] ctx));
      (*(data_at Tsh (tarray tuchar (Zlength [i])) [Vint (Int.repr i)] sep);*)
      (K_vector kv);FRZL FR6; 
      (*(data_at Tsh (tarray tuchar (Zlength V)) (map Vint (map Int.repr V))
          (field_address t_struct_hmac256drbg_context_st [StructField _V] ctx));
      (field_at Tsh t_struct_hmac256drbg_context_st
          [StructField _reseed_counter] (Vint (Int.repr reseed_counter)) ctx);
      (field_at Tsh t_struct_hmac256drbg_context_st
          [StructField _entropy_len] (Vint (Int.repr entropy_len)) ctx);
      (field_at Tsh t_struct_hmac256drbg_context_st
          [StructField _prediction_resistance] (Val.of_bool prediction_resistance) ctx);
      (field_at Tsh t_struct_hmac256drbg_context_st
          [StructField _reseed_interval] (Vint (Int.repr reseed_interval))
          ctx);
      (data_at Tsh t_struct_mbedtls_md_info info_contents
          (hmac256drbgstate_md_info_pointer
             (md_ctx,
         (V',
         (reseed_counter',
         (entropy_len', (Val.of_bool prediction_resistance, reseed_interval')))))));
      (data_at_ Tsh (tarray tuchar (Zlength V)) K);*)
      (da_emp Tsh (tarray tuchar (Zlength contents))
          (map Vint (map Int.repr contents)) additional)) 
    ). (* 4.4 *)
    { 
      (* rounds = 2 case *)
      destruct na; rewrite Heqrounds in *. Focus 2. inv H7. clear H7.
      subst rounds. simpl in Heqna.
      assert (isptr additional) as Hisptr_add.
      { (*subst add_len. clear - H7 PNadditional Heqrounds (*NA*)Heqnon_empty_additional.
        subst.*)
        (*destruct (initial_world.EqDec_Z add_len 0); simpl in *. rewrite andb_false_r in Heqna. discriminate .*)
        destruct additional; simpl in PNadditional; try contradiction.
        subst i0; simpl in *; discriminate. trivial.
        (*unfold nullval in H7; simpl in H7. inv H7. *)
      }
      clear PNadditional.
      destruct additional; try contradiction. clear Hisptr_add.
      simpl in Heqna. destruct H1; subst add_len. 2: simpl in Heqna; discriminate.
      rewrite da_emp_ptr. Intros.

      (* mbedtls_md_hmac_update( &ctx->md_ctx, additional, add_len ); *)
      Time forward_call (key, field_address t_struct_hmac256drbg_context_st [StructField _md_ctx] ctx,
                         (*md_ctx*)(IS1a, (IS1b, IS1c)), Vptr b i0, V ++ [i], contents, kv). (*LENB: 8=9.5, Naphat:  63 *)
(*      {
        (* prove the parameters match up *)
        entailer!.
      }*)
      {
        (* prove the PROP clause matches *)
        repeat split; [omega | omega | | assumption].
        rewrite Zlength_app; rewrite H9.
        simpl. remember (Zlength contents) as n; clear - H.
        destruct H. rewrite <- Zplus_assoc.
        unfold Int.max_unsigned in H0.
        rewrite hmac_pure_lemmas.IntModulus32 in H0; rewrite two_power_pos_equiv.
        simpl. simpl in H0.
        assert (H1: Z.pow_pos 2 61 = 2305843009213693952) by reflexivity; rewrite H1; clear H1.
        omega.
      }
      (* prove the post condition of the if statement *)
      rewrite <- app_assoc.
      (*Intros v.
      rewrite H10.*) rewrite H9. rewrite da_emp_ptr. 
      entailer!. (*subst add_len; trivial.
      destruct (eq_dec (Vptr b i0) nullval); simpl in *; try discriminate.
      destruct (initial_world.EqDec_Z (Zlength contents) 0); trivial; discriminate. *)
    }
    {
      (* rounds <> 2 case *)
      assert (RNDS1: rounds = 1).
      { subst rounds.
        destruct na; trivial; elim H7; trivial. }
      rewrite RNDS1 in *; clear H7 H4.
      assert (NAF: na = false).
      { destruct na; try omega. trivial. }
      rewrite NAF in *. clear Heqrounds.
      forward. rewrite H9, NAF.
      destruct additional; try contradiction; simpl in PNadditional.
      + subst i0. rewrite da_emp_null; trivial. entailer!.
      + rewrite da_emp_ptr. Intros. normalize. entailer!. 
    }

    (* mbedtls_md_hmac_finish( &ctx->md_ctx, K ); *)
    thaw FR6. freeze [3;4;5;6;8] FR8.  rewrite H9.
    rewrite data_at__memory_block. change (sizeof (*cenv_cs*) (tarray tuchar 32)) with 32.
    Intros.
    Time forward_call ((V ++ [i] ++ (if na then contents else [])), key, 
                       field_address t_struct_hmac256drbg_context_st [StructField _md_ctx] ctx, 
                       (*md_ctx*)(IS1a, (IS1b, IS1c)), K, Tsh, kv). (*LENB: 7, Naphat 62 *)
    (*{
      (* prove the parameters match up *)
      entailer!.
    }*)
    (*Side condition now automatically discharged
    {
      change (sizeof cenv_cs (tarray tuchar (Z.of_nat SHA256.DigestLength))) with 32.
      cancel.
    }*)
    Intros.
    freeze [0;1;2;4] FR9.
    rewrite data_at_isptr with (p:=K). Intros.
    (*destruct K; try solve [contradiction].*)
    thaw FR9.
    replace_SEP 1 (UNDER_SPEC.EMPTY (snd (snd (*md_ctx*)(IS1a, (IS1b, IS1c))))) by (entailer!; apply UNDER_SPEC.FULL_EMPTY).

    (* mbedtls_md_hmac_starts( &ctx->md_ctx, K, md_len ); *)
    Time forward_call (field_address t_struct_hmac256drbg_context_st [StructField _md_ctx] ctx,
                       (*md_ctx*)(IS1a, (IS1b, IS1c)), 
                       (Zlength (HMAC256 (V ++ [i] ++ (if na then contents else [])) key)),
                       HMAC256 (V ++ [i] ++ (if na then contents else [])) key, kv, K). (*14; Naphat 75 *)
    {
      (* prove the function parameters match up *)
      apply prop_right. destruct K; try solve [contradiction].
      rewrite hmac_common_lemmas.HMAC_Zlength, FA_ctx_MDCTX; simpl.
      rewrite offset_val_force_ptr, isptr_force_ptr, sem_cast_neutral_ptr; trivial. auto.
    }
    { 
      split.
      + (* prove that output of HMAC can serve as its key *)
        unfold spec_hmac.has_lengthK; simpl.
        repeat split; try reflexivity; rewrite hmac_common_lemmas.HMAC_Zlength;
        hnf; auto.
      + (* prove that the output of HMAC are bytes *)
        apply hmac_common_lemmas.isbyte_hmac.
    }
    Intros. 

    thaw FR8. freeze [2;4;6;7;8] FR9. 
(*    assert_PROP (field_compatible t_struct_hmac256drbg_context_st [StructField _V] ctx) as FC_vctx_V by entailer!.*)
    (* mbedtls_md_hmac_update( &ctx->md_ctx, ctx->V, md_len ); *)
    Time forward_call (HMAC256 (V ++ [i] ++ (if na then contents else [])) key,
                       field_address t_struct_hmac256drbg_context_st [StructField _md_ctx] ctx, 
                       (*md_ctx*)(IS1a, (IS1b, IS1c)),
                       field_address t_struct_hmac256drbg_context_st [StructField _V] ctx, @nil Z, V, kv). (*9; Naphat 72 *)
    {
      (* prove the function parameters match up *)
      rewrite H9, FA_ctx_V. apply prop_right. destruct ctx; try contradiction. split; reflexivity.
    }
    (*{
      (* prove the function SEP clauses match up *)
      rewrite H9; cancel.
    }*)
    {
      (* prove the PROP clauses *)
      rewrite H9.
      repeat split; [hnf;auto | hnf;auto | assumption].
    }
    Intros.
    rewrite H9.
(*    normalize.*)
    replace_SEP 2 (memory_block Tsh (sizeof (*cenv_cs*) (tarray tuchar 32)) (field_address t_struct_hmac256drbg_context_st [StructField _V] ctx)) by (entailer!; apply data_at_memory_block).
    simpl.
    (* mbedtls_md_hmac_finish( &ctx->md_ctx, ctx->V ); *)
    Time forward_call (V, HMAC256 (V ++ i::(if na then contents else [])) key, 
                       field_address t_struct_hmac256drbg_context_st [StructField _md_ctx] ctx, 
                       (*md_ctx*)(IS1a, (IS1b, IS1c)),
                       field_address t_struct_hmac256drbg_context_st [StructField _V] ctx, Tsh, kv). (*9; Naphat: 75 *)
    (*{
      (* prove the function parameters match up *)
      entailer!.
    }*)
    Time old_go_lower. (*24 secs, 1.45GB -> 1.55GB*)(*necessary due to existence of local () && in postcondition of for-rule!!!*)
    normalize. 
    Exists (HMAC256 (V ++ [i] ++ (if na then contents else [])) key).

    apply andp_right. (*Time solve [entailer!].*) apply prop_right. repeat split; auto; omega. 

    Exists (HMAC256 V (HMAC256 (V ++ [i] ++ (if na then contents else [])) key)).
    Exists (HMAC256DRBGabs (HMAC256 (V ++ [i] ++ (if na then contents else [])) key)
                           (HMAC256 V (HMAC256 (V ++ [i] ++ (if na then contents else [])) key)) reseed_counter entropy_len prediction_resistance reseed_interval).
    normalize.
    apply andp_right. apply prop_right. repeat split; eauto.
      subst initial_key initial_value.
      apply HMAC_DRBG_update_round_incremental_Z; try eassumption. omega.
      apply hmac_common_lemmas.HMAC_Zlength.
    cancel.
    thaw FR9. cancel.
    unfold hmac256drbgabs_common_mpreds, hmac256drbgabs_to_state.
    unfold hmac256drbgstate_md_FULL.
    unfold hmac256drbg_relate.
    rewrite (*H1,*) hmac_common_lemmas.HMAC_Zlength. rewrite hmac_common_lemmas.HMAC_Zlength.
    cancel.
    unfold md_full. entailer!.
    { apply hmac_common_lemmas.HMAC_Zlength. }
    repeat rewrite sepcon_assoc. rewrite sepcon_comm. apply sepcon_derives. 2: apply derives_refl.
    unfold_data_at 3%nat.
    thaw OtherFields. cancel.
    rewrite (field_at_data_at _ _ [StructField _md_ctx]);
    rewrite (field_at_data_at _ _ [StructField _V]).
idtac "Timing the Qed of loopbody". cancel.
Time Qed.
 (*Feb 23rd, ie after merging semaxpost''-update: Finished transaction in 6180.062 secs (184.093u,0.375s) (successful)*)
 (*Feb22nd 2017: Finished transaction in 2441.578 secs (275.296u,1.437s) (successful) *)
 (*earlier: 266 secs (42u,0.015s) in Coq8.5pl2*)
 (*Dec 3rd, 2016: 1128secs (347u, 3.5s) in 8.5pl2 on laptop; laptop-make: 234s, (234u), total processing time for file: 8m17s*)
 (*Dec 6th, 2016: 1217.59 secs (435.912u,7.552s) in 8.5pl2 on laptop; laptop-make: 249.252 secs (249.328u,0.051s), 8m33s for file*)

Lemma body_hmac_drbg_update: semax_body HmacDrbgVarSpecs HmacDrbgFunSpecs 
       f_mbedtls_hmac_drbg_update hmac_drbg_update_spec.
Proof.
  start_function. 
  rename lvar0 into sep.
  rename lvar1 into K.
  abbreviate_semax.
  destruct initial_state as [IS1 [IS2 [IS3 [IS4 [IS5 IS6]]]]].
  rewrite da_emp_isptrornull. 

  (* info = md_ctx.md_info *)
  destruct IS1 as [IS1a [IS1b IS1c]]. simpl.
  rewrite data_at_isptr with (p:=ctx). 
  unfold hmac256drbgstate_md_info_pointer. simpl.
  rewrite data_at_isptr with (p:=IS1a). 
  normalize.
  freeze [0;1;2;4;6] FR0. 
  freeze [0;2] FR1.

  Time forward. (*8.5pl2: 3secs. BUT without doing the 2 lines
     unfold hmac256drbgstate_md_info_pointer. simpl.
     rewrite data_at_isptr with (p:=IS1a),
     this
     entailer takes 1230secs.
     And when we leave the IS1a-data-at unfrozen (eg omit the construction of FR1), it also takes significantly more than 3 secs*)
  thaw FR1.

  (* md_len = mbedtls_md_get_size( info ); *)
  freeze [0;1] FR1.
  forward_call tt.

  (*Intros md_len. LENB: replaced by the following*)
  change (Z.of_nat SHA256.DigestLength) with 32.
(*  remember (Vint (Int.repr (Z.of_nat SHA256.DigestLength))) as md_len.*)

  (* rounds = ( additional != NULL && add_len != 0 ) ? 2 : 1; *)
(*  remember (if eq_dec add_len 0 then false else if eq_dec additional nullval then false else true) as non_empty_additional.*)
  remember (andb (negb (eq_dec additional nullval)) (negb (eq_dec add_len 0))) as na.
  freeze [0;1] FR2. clear PIS1a.
  forward_if (
      PROP  ()
      LOCAL  (temp _md_len (Vint (Int.repr 32)); lvar _K (tarray tuchar 32) K;
      temp _ctx ctx;
      lvar _sep (tarray tuchar 1) sep;
      temp _additional additional; temp _add_len (Vint (Int.repr add_len));
      temp _t'2 (Val.of_bool na);
(*      temp 225x%positive (Val.of_bool non_empty_additional);*)
      gvar sha._K256 kv)
      SEP  (FRZL (FR2))). 
  {
    (* show that add_len <> 0 implies the post condition *)
    forward.
    { entailer. destruct additional; try contradiction; simpl in PNadditional.
      subst i; simpl. entailer!. (* simpl. *)
      thaw FR2. thaw FR1. thaw FR0. normalize.
      rewrite da_emp_ptr.
      apply denote_tc_comparable_split; auto 50 with valid_pointer.
      (* TODO regression, this should have solved it *) 
      apply sepcon_valid_pointer1.
      apply sepcon_valid_pointer1.
      apply sepcon_valid_pointer1.
      apply sepcon_valid_pointer1.
      apply sepcon_valid_pointer2. normalize.
      apply data_at_valid_ptr; auto.

(*      simpl. clear - H4 H. rewrite Zmax_right; omega.*)
    } 

    { entailer!.
      destruct additional; simpl in PNadditional; try contradiction.
      subst i; simpl; trivial.
      simpl. destruct (initial_world.EqDec_Z add_len 0); trivial; omega.
    }
  } 

  {
    (* show that add_len = 0 implies the post condition *)
    forward. 
    entailer!. (*rewrite H4.*) simpl. rewrite andb_false_r. reflexivity. 
  }

  remember (update_rounds na) as rounds. unfold update_rounds in Heqrounds.
  forward_if ( PROP  ()
      LOCAL  (temp _md_len (Vint (Int.repr 32)); lvar _K (tarray tuchar 32) K;
      temp _ctx ctx;
      lvar _sep (tarray tuchar 1) sep;
      temp _additional additional; temp _add_len (Vint (Int.repr add_len));
(*      temp 141x%positive (Vint (Int.repr rounds));*)
      temp _t'3 (Vint (Int.repr rounds));
      gvar sha._K256 kv
             )
      SEP  (FRZL FR2) 
  ).
  {
    (* non_empty_additional = true *)
    forward. rewrite H4 in *; clear H4.
    entailer!.
  }
  {
    (* non_empty_additional = false *)
    forward. rewrite H4 in *; clear H4.
    entailer!.
  }

  forward.
  drop_LOCAL 7%nat.
  remember (hmac256drbgabs_key initial_state_abs) as initial_key.
  remember (hmac256drbgabs_value initial_state_abs) as initial_value.

  (* verif_sha_final2.v, @exp (environ -> mpred) *)
  (* for ( sep_value = 0; sep_value < rounds; sep_value++ ) *)
  Time forward_for_simple_bound rounds (EX i: Z,
      PROP  (
      (* (key, value) = HMAC_DRBG_update_round HMAC256 (map Int.signed contents) old_key old_value 0 (Z.to_nat i);
      (*
      le i (update_rounds non_empty_additional);
       *)
      key = hmac256drbgabs_key final_state_abs;
      value = hmac256drbgabs_value final_state_abs;
      hmac256drbgabs_metadata_same final_state_abs state_abs *)
        ) 
      LOCAL ((*In VST 1.6, we need to add the entry for temp*)
               temp _rounds (Vint (Int.repr rounds));
       temp _md_len (Vint (Int.repr 32));
       temp _ctx ctx;
       lvar _K (tarray tuchar 32) K; lvar _sep (tarray tuchar 1) sep;
       temp _additional additional; temp _add_len (Vint (Int.repr add_len));
       gvar sha._K256 kv
         )
      SEP  (
        (EX key: list Z, EX value: list Z, EX final_state_abs: hmac256drbgabs,
          !!(
              (key, value) = HMAC_DRBG_update_round HMAC256 
                (*contents*) (if na then contents else [])
                initial_key initial_value (Z.to_nat i)
              /\ key = hmac256drbgabs_key final_state_abs
              /\ value = hmac256drbgabs_value final_state_abs
              /\ hmac256drbgabs_metadata_same final_state_abs initial_state_abs
              /\ Zlength value = Z.of_nat SHA256.DigestLength
              /\ Forall general_lemmas.isbyteZ value
            ) &&
           (hmac256drbgabs_common_mpreds final_state_abs 
             (*initial_state*) ((IS1a,(IS1b,IS1c)),(IS2,(IS3,(IS4,(IS5,IS6)))))
              ctx info_contents)
         );
        (* `(update_relate_final_state ctx final_state_abs); *)
        (data_at_ Tsh (tarray tuchar 32) K);
        (da_emp Tsh (tarray tuchar (Zlength contents)) (map Vint (map Int.repr contents)) additional);
        (data_at_ Tsh (tarray tuchar 1) sep );
        (K_vector kv)
         )
  ). (* 2 *)
  {
    (* Int.min_signed <= 0 <= rounds *)
    rewrite Heqrounds; destruct na; auto.
  }
  {
    (* rounds <= Int.max_signed *)
    rewrite Heqrounds; destruct na; auto.
  }
  {
    (* pre conditions imply loop invariant *)
    entailer!. 
    Exists (hmac256drbgabs_key initial_state_abs) (hmac256drbgabs_value initial_state_abs) initial_state_abs.
    destruct initial_state_abs. simpl. Time entailer!.
    thaw FR2. thaw FR1. thaw FR0. cancel.
    unfold hmac256drbgabs_common_mpreds, hmac256drbgabs_to_state. cancel.
    unfold hmac256drbg_relate. entailer!. 
  }
  {
    (* loop body *)
(*    change (`(eq (Vint (Int.repr rounds))) (eval_expr (Etempvar _rounds tint))) with (temp _rounds (Vint (Int.repr rounds))).*)
    Intros key value state_abs. normalize.
    clear FR2 FR1 FR0.

    (*( semax_subcommand HmacDrbgVarSpecs HmacDrbgFunSpecs 
       f_mbedtls_hmac_drbg_update hmac_drbg_update_spec.*)

    (*unfold MORE_COMMANDS, POSTCONDITION, abbreviate.*)

    eapply loopbody; eassumption.
    (* eapply hmac_drbg_update_loop; try eassumption; try reflexivity. 
      eapply hmac_drbg_update_loop; try eassumption. reflexivity.
      rewrite Heqna. clear - PNadditional.
      destruct additional; simpl in PNadditional; try contradiction.
      subst; simpl. destruct (initial_world.EqDec_Z add_len 0); trivial.
      simpl. destruct (initial_world.EqDec_Z add_len 0); trivial.*)
  }

  Intros key value final_state_abs.
  (* return *)
  forward.

  (* prove function post condition *)
  Exists K sep.
  unfold hmac256drbgabs_hmac_drbg_update.
  unfold HMAC256_DRBG_functional_prog.HMAC256_DRBG_update.
  destruct initial_state_abs.
  rewrite HMAC_DRBG_update_concrete_correct.
  Time entailer!. (* 2 *)

  rename H4 into Hupdate_rounds.
  rename H7 into Hmetadata.
  destruct final_state_abs; unfold hmac256drbgabs_metadata_same in Hmetadata. clear FR2 FR1 FR0.
  destruct Hmetadata as [Hreseed_counter [Hentropy_len [Hpr Hrseed_interval]]]; subst.
  replace (HMAC_DRBG_update_concrete HMAC256 (*contents*) (contents_with_add additional add_len contents)  key V) with (key0, V0). apply derives_refl.
(*  cancel.
  replace (HMAC_DRBG_update_concrete HMAC256 (*contents*) (if (negb (eq_dec additional nullval) &&
                      negb (eq_dec (Zlength contents) 0))%bool then contents else []) key V) with (key0, V0). apply derives_refl.
  cancel.*)
  unfold hmac256drbgabs_key, hmac256drbgabs_value in Hupdate_rounds. 
  rewrite Hupdate_rounds in *. unfold HMAC_DRBG_update_concrete.
  f_equal.
  clear - H1 PNadditional. unfold contents_with_add.
  destruct additional; simpl in PNadditional; try contradiction.
  + subst i ; simpl; trivial.
  + simpl. destruct (initial_world.EqDec_Z add_len 0); simpl; trivial.
    destruct H1; try solve[omega].
    subst add_len. destruct contents; simpl; trivial. elim n.
idtac "Timing the Qed of hmacdrbg_update". apply Zlength_nil.
Time Qed. (*Feb 22nd 2017: 68.655 secs (62.937u,0.187s) (successful)
           Dec 6th: 24s (laptop)*)
