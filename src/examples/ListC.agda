{-# OPTIONS --safe #-}
module examples.ListC where

open import Prelude
open import Day1

module Helpers where

  record Iso (A B : Type₀) : Type₀ where
    field
      to      : A → B
      from    : B → A
      to-from : {x : A} → from (to x) ≡ x
      from-to : {y : B} → to (from y) ≡ y

  subst : {A : Type₀} {x y : A} {B : A → Type₀} → x ≡ y → B x → B y
  subst (refl _) p = p

  Σ-≡ : {A : Type₀} {B : A → Type₀} {P Q : Σ a ꞉ A , B a} →
        (basePath : fst P ≡ fst Q) → (liftedPath : subst basePath (snd P) ≡ snd Q) →
        P ≡ Q
  Σ-≡ (refl _) (refl _) = refl _

  uncurry : {A C : Type₀} {B : A → Type₀} →
          ((a : A) → B a → C) → (Σ A B) → C
  uncurry f (a , b) = f a b

open Helpers


record Cont : Type₁ where
  constructor _▷_
  field
    Shape    : Type₀
    Position : Shape → Type₀
open Cont

⟦_⟧ : Cont → Type₀ → Type₀
⟦ S ▷ P ⟧ X = Σ s ꞉ S , (P s → X)

List′ : Cont
List′ = ℕ ▷ Fin


module _ {fun-ext : {A B : Type₀} {f g : A → B} → ((x : A) → f x ≡ g x) → f ≡ g} where

  yes-it's-the-same-list : {A : Type₀} →
                           Iso (List A) (⟦ List′ ⟧ A)
  yes-it's-the-same-list = record
    { to      = to
    ; from    = uncurry from
    ; to-from = to-from _
    ; from-to = from-to _ _
    } where

      to : {A : Type₀} →
           List A → ⟦ List′ ⟧ A
      to []       = 0 , λ ()
      to (x ∷ xs) with to xs
      ... | n , lookup = suc n , shift lookup x
        where
        shift : {A : Type₀} {n : ℕ}
                (lookup : Fin n → A) → A → (Fin (suc n) → A)
        shift _      x fzero    = x
        shift lookup _ (fsuc f) = lookup f

      from : {A : Type₀}
             (n : ℕ) → (Fin n → A) → List A
      from zero    _      = []
      from (suc n) lookup = lookup fzero ∷ from n (λ i → lookup (fsuc i))

      to-from : {A : Type₀}
                (xs : List A) → uncurry from (to xs) ≡ xs
      to-from []       = refl []
      to-from (x ∷ xs) with to xs | to-from xs
      ... | n , lookup | refl _ = cong (x ∷_) (refl _)

      from-to : {A : Type₀}
                (n : ℕ) (lookup : Fin n → A) → to (uncurry from (n , lookup)) ≡ (n , lookup)
      from-to zero    _ = cong (0 ,_) (fun-ext λ ())
      from-to (suc n) lookup rewrite from-to n (λ i → lookup (fsuc i)) = Σ-≡ (cong suc (refl _)) (fun-ext λ { fzero → refl _ ; (fsuc _) → refl _ })
