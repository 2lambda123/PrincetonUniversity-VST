Require Import floyd.proofauto.
Import ListNotations.
Require Import Blist.

Require Import sha.vst_lemmas.
Require Import sha.hmac_pure_lemmas.
Require Import ByteBitRelations.

Require sha.sha.
Require Import sha.SHA256.
Local Open Scope logic.

Require Import sha.spec_sha.
Require Import sha_lemmas.

Require Import sha.HMAC_functional_prog.
Require Import sha.HMAC256_functional_prog.
Require Import sha.hmac_common_lemmas.
Require Import ShaInstantiation.
Require Import HMAC256_equivalence.
Require Import HMAC256_isPRF.

Require Import sha.hmac.
Require Import sha.spec_hmac.

Lemma key_vector l:
  length (bytesToBits (HMAC_SHA256.mkKey l)) = b.
Proof. rewrite bytesToBits_len, hmac_common_lemmas.mkKey_length; reflexivity. Qed.

Definition mkCont (l:list Z) : HMAC_spec_abstract.HMAC_Abstract.Message (fun x => x=bytesToBits l /\ NPeano.divide 8 (length x)).
eapply exist. split. reflexivity. 
rewrite bytesToBits_len. exists (length l). trivial.
Qed.

Definition bitspec KEY MSG :=
  Vector.to_list ( HMAC_spec.HMAC EQ.h_v iv_v (HMAC_spec_abstract.HMAC_Abstract.wrappedSAP _ _ splitAndPad_v)
                      fpad_v EQ.opad_v EQ.ipad_v
                      (of_list_length _ (key_vector (CONT KEY)))
                      (mkCont (CONT MSG))).

Definition CRYPTO (A : Comp.OracleComp (HMAC_spec_abstract.HMAC_Abstract.Message PARS256.P)
                                       (Bvector.Bvector c) bool) 
                  (A_wf : DistSem.well_formed_oc A):=
           forall tau eps sig, PRFMod.h_PRF A tau ->
                               PRFMod.h_star_WCR A eps ->
                               PRFMod.dual_h_RKA A sig ->
  PRFMod.isPRF (Comp.Rnd (HMAC_PRF.b c p))
    (Comp.Rnd c)
    (HMAC_PRF.HMAC PRFMod.M.h_v EQ256.iv_v
      (HMAC_spec_abstract.HMAC_Abstract.wrappedSAP _ _ splitAndPad_v) EQ256.fpad_v PRFMod.M.opad_v PRFMod.M.ipad_v)
    PRFMod.Message_eqdec
    (EqDec.Bvector_EqDec c)
    (Rat.ratAdd (Rat.ratAdd tau eps) sig) A.

Definition HMAC_crypto :=
  DECLARE _HMAC
   WITH keyVal: val, KEY:DATA,
        msgVal: val, MSG:DATA,
        kv:val, shmd: share, md: val
   PRE [ _key OF tptr tuchar,
         _key_len OF tint,
         _d OF tptr tuchar,
         _n OF tint,
         _md OF tptr tuchar ]
         PROP (writable_share shmd; 
               has_lengthK (LEN KEY) (CONT KEY);
               has_lengthD 512 (LEN MSG) (CONT MSG))
         LOCAL (temp _md md; temp _key keyVal;
                temp _key_len (Vint (Int.repr (LEN KEY)));
                temp _d msgVal; temp _n (Vint (Int.repr (LEN MSG)));
                gvar sha._K256 kv)
         SEP(data_block Tsh (CONT KEY) keyVal;
             data_block Tsh (CONT MSG) msgVal;
             K_vector kv;
             memory_block shmd 32 md)
  POST [ tvoid ] 
         EX digest:_,
          PROP (bytesToBits digest = bitspec KEY MSG /\ 
                forall A Awf, CRYPTO A Awf)
          LOCAL ()
          SEP(K_vector kv;
              data_block shmd digest md;
              initPostKey keyVal (CONT KEY);
              data_block Tsh (CONT MSG) msgVal).

Lemma body_hmac_crypto: semax_body HmacVarSpecs HmacFunSpecs 
      f_HMAC HMAC_crypto.
Proof.
start_function.
name key' _key.
name keylen' _key_len.
name d' _d.
name n' _n.
name md' _md. rename lvar0 into c.
rename keyVal into k. rename msgVal into d.
rename H into KL. rename H0 into DL.
destruct KEY as [kl key].
destruct MSG as [dl data]. simpl in *.
rewrite memory_block_isptr. normalize.
(*NEW: crypto proof requires that we first extract isbyteZ key*)
assert_PROP (Forall isbyteZ key) as isbyteZ_key by entailer!.

forward_if  (
  PROP  (isptr c)
   LOCAL  (lvar _c t_struct_hmac_ctx_st c; temp _md md; temp _key k;
      temp _key_len (Vint (Int.repr kl)); temp _d d;
       temp _n (Vint (Int.repr dl)); gvar sha._K256 kv)
   SEP  (data_at_ Tsh t_struct_hmac_ctx_st c; data_block Tsh key k;
         data_block Tsh data d; K_vector kv;
         memory_block shmd 32 md)).
  { apply denote_tc_comparable_split. 
    apply sepcon_valid_pointer2. apply memory_block_valid_ptr. auto. omega.
    apply valid_pointer_zero. }
  { (* Branch1 *) exfalso. subst md. contradiction.  }
  { (* Branch2 *) forward. entailer. } 
normalize.
assert_PROP (isptr k). { unfold data_block. normalize. rewrite data_at_isptr with (p:=k). entailer!. (*Issue: need to do unfold data_block. normalize. rewrite data_at_isptr with (p:=k). here is NEW*) }
rename H into isPtrK. 
forward_call (c, k, kl, key, kv, HMACabs nil nil nil).
  { apply isptrD in isPtrK. destruct isPtrK as [kb [kofs HK]]. rewrite HK.
    unfold initPre. entailer!. 
  }
assert_PROP (s256a_len (absCtxt (hmacInit key)) = 512).
  { unfold hmacstate_. Intros r. apply prop_right. apply H. }
rename H into absH_len512.

forward_call (hmacInit key, c, d, dl, data, kv). 
  { rewrite absH_len512. assumption. } 

(* Call to HMAC_Final*)
assert_PROP (@field_compatible CompSpecs (Tstruct _hmac_ctx_st noattr) nil c).
{ unfold hmacstate_.  Intros r; entailer!. }
rename H into FC_c.

forward_call (hmacUpdate data (hmacInit key), c, md, shmd, kv).
remember (hmacFinal (hmacUpdate data (hmacInit key))) as RES.
destruct RES as [h2 dig].
simpl.

forward_call (h2,c).
forward.
assert_PROP (field_compatible (tarray tuchar (sizeof t_struct_hmac_ctx_st)) nil c).
{ unfold data_block at 1. unfold Zlength. simpl. rewrite data_at_data_at'. normalize. }
rename H5 into FC.
specialize (hmac_sound key data). unfold hmac. 
rewrite <- HeqRES. simpl; intros.
Exists c dig. 
(*clear - FC FC_c H7 H8 isbyteZ_key H0.*)
Time normalize. (*6.4*) (*calling entailer! here takes > 13 secs*)
apply andp_right. apply prop_right. subst.
       split. unfold bitspec. simpl. rewrite Equivalence.
         f_equal. unfold HMAC_spec_abstract.HMAC_Abstract.Message2Blist.
         remember (mkCont data) as dd. destruct dd. destruct a; subst x.
         rewrite ByteBitRelations.bytes_bits_bytes_id.
         rewrite HMAC_equivalence.of_length_proof_irrel.
         rewrite ByteBitRelations.bytes_bits_bytes_id. reflexivity.
           apply isbyteZ_mkKey. assumption.   
           assumption.
           intros ? X. apply X.
       split; trivial. split; trivial. 
       intros ? X.
        unfold CRYPTO; intros. apply HMAC256_isPRF; assumption.
cancel.
  unfold data_block.
  rewrite Zlength_correct; simpl.
  apply andp_left2.
  rewrite <- memory_block_data_at_; trivial.
  rewrite (memory_block_data_at_ Tsh 
                    (tarray tuchar (@sizeof (@cenv_cs CompSpecs) (Tstruct _hmac_ctx_st noattr)))).
  2: trivial.
  eapply derives_trans. apply data_at_data_at_. apply derives_refl.
Qed.