Require
  theory.naturals.
Require Import 
  Program Morphisms Setoid Ring
  abstract_algebra interfaces.naturals interfaces.additional_operations.

(* * Properties of Nat Pow *)
Section nat_pow_properties.
  Context `{SemiRing A} `{Naturals B}.

  Add Ring A: (rings.stdlib_semiring_theory A).
  Add Ring B: (rings.stdlib_semiring_theory B).

  Global Instance nat_pow_spec_proper: Proper ((=) ==> (=) ==> (=) ==> iff) nat_pow_spec.
  Proof with eauto.
    intros x1 x2 E n1 n2 F y1 y2 G. 
    split; intro. eapply nat_pow_spec_proper'...
    eapply nat_pow_spec_proper'; try symmetry...
  Qed.

  Tactic Notation "gen_eq" constr(c) "as" ident(x) :=
    set (x := c) in *;
    let H := fresh in (assert (H : x = c) by reflexivity; clearbody x; revert H).

  Lemma nat_pow_spec_unique x n y1 y2 : 
    nat_pow_spec x n y1 → nat_pow_spec x n y2 → y1 = y2.
  Proof with eauto; try reflexivity.
    intros E F. generalize dependent y2. 
    induction E as [ | | ? ? ? ? ? ? G1 G2 G3]. 
    
    intros.
    gen_eq (0:B) as n. induction F as [ |  | ? ? ? ? ? ? G1 G2 G3 ]; intros...
    destruct (naturals.nz_one_plus_zero n)...
    rewrite <-G3. apply IHF. rewrite G2...

    intros.
    gen_eq (1+n) as m. generalize dependent n. generalize dependent y. 
    induction F as [ | | ? ? ? ? ? ? G1 G2 G3 ]; intros ? ? ? ? G4.
    destruct (naturals.nz_one_plus_zero n). symmetry...
    apply sg_mor... apply IHE. 
    apply (left_cancellation (+) 1) in G4... 
    symmetry in G4. eapply nat_pow_spec_proper...
    rewrite <-G1, <-G3. apply (IHF _ n)... eapply nat_pow_spec_proper...
    intros. apply IHE. symmetry in G1. eapply nat_pow_spec_proper... rewrite G2...
 
    intros. rewrite <-G3. apply IHE. eapply nat_pow_spec_proper... 
  Qed.

  Section nat_pow_spec_from_properties.
  Context (f : A → B → A) ( f_proper : Proper ((=) ==> (=) ==> (=)) f )
    ( f_0 : ∀x, f x 0 = 1 ) ( f_S : ∀ x n,  f x (1+n) = x * (f x n) ).

  Lemma nat_pow_spec_from_properties x n : nat_pow_spec x n (f x n).
  Proof with eauto; try reflexivity.
    revert n. apply naturals.induction.
    intros ? ? E. rewrite E...
    rewrite f_0. apply nat_pow_spec_0...
    intros. rewrite f_S. eapply nat_pow_spec_S...
  Qed.
  End nat_pow_spec_from_properties.

  Context `{np : !NatPow A B}.
  Global Instance: Proper ((=) ==> (=) ==> (=)) (^).
  Proof with eauto.
    intros x1 x2 E y1 y2 F. 
    unfold nat_pow, nat_pow_sig. do 2 destruct np. simpl.
    eapply nat_pow_spec_unique...
    eapply nat_pow_spec_proper... reflexivity. 
  Qed.

  Lemma nat_pow_0 x : x ^ 0 = 1.
  Proof with eauto.
   unfold nat_pow, nat_pow_sig. destruct np. simpl.
   eapply nat_pow_spec_unique... apply nat_pow_spec_0.
  Qed.

  Lemma nat_pow_S x n : x ^ (1+n) = x * x ^ n.
  Proof with eauto.
   unfold nat_pow, nat_pow_sig. do 2 destruct np. simpl.
   eapply nat_pow_spec_unique... eapply nat_pow_spec_S...
  Qed.

  Instance: RightIdentity (^) 1.
  Proof. 
    intro. assert ((1:B) = 1 + 0) as E by ring. rewrite E.
    rewrite nat_pow_S, nat_pow_0. ring.
  Qed.
  
  Lemma nat_pow_exp_sum (x y: B) (n: A) : 
    n ^ (x + y) = n ^ x * n ^ y.
  Proof with auto.
    pattern x. apply naturals.induction; clear x.
    intros ? ? E. rewrite E. tauto.
    rewrite nat_pow_0, left_identity. ring.
    intros x E. 
    rewrite <-associativity.
    do 2 rewrite nat_pow_S.
    rewrite E. ring.
  Qed.
  
  Context `{!NoZeroDivisors A} `{!ZeroNeOne A}.

  Lemma nat_pow_nonzero (x: B) (n: A) : n ≠ 0 → n ^ x ≠ 0.
  Proof with eauto.
    pattern x. apply naturals.induction; clear x.
    intros x1 x2 E. rewrite E. tauto.
    intros. rewrite nat_pow_0. apply not_symmetry. apply zero_ne_one.
    intros x E F G. rewrite nat_pow_S in G.
    apply (no_zero_divisors n); split... 
  Qed. 
End nat_pow_properties.

(* Very slow default implementation by translation into Peano *)
Section nat_pow_default.
  Context A B `{SemiRing A} `{Naturals B}.
  
  Fixpoint nat_pow_rec (x: A) (n : nat) : A := match n with
  | 0 => 1
  | S n => x * (nat_pow_rec x n)
  end.

  Instance: Proper ((=) ==> (=) ==> (=)) nat_pow_rec.
  Proof with try reflexivity.
   intros x y E a ? [].
   induction a; simpl...
   rewrite IHa, E...
  Qed.

  Let nat_pow_default x n := nat_pow_rec x (naturals_to_semiring B nat n).
  Global Program Instance: NatPow A B | 10 := nat_pow_default.
  Next Obligation with simpl; try reflexivity.
    apply nat_pow_spec_from_properties; unfold nat_pow_default.
    intros ? ? E ? ? F. rewrite E, F...
    intros. rewrite rings.preserves_0...
    intros. rewrite rings.preserves_plus, rings.preserves_1, <-peano_naturals.S_nat_1_plus...
  Qed.
End nat_pow_default.
