;; Rare Token - simple fungible token used to force-evolve the NFT
;; Symbol: RARE, Decimals: 0

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-FUNDS (err u101))
(define-constant ERR-BAD-ARGS (err u102))

(define-data-var owner principal tx-sender)
(define-data-var total-supply uint u0)
(define-constant token-symbol "RARE")
(define-constant token-name "Evolve Rare Token")
(define-constant token-decimals u0)

;; price in microSTX per token
(define-data-var price-per-token uint u1000000) ;; 1 STX

(define-map balances
    { who: principal }
    { balance: uint }
)

(define-read-only (get-owner)
    (ok (var-get owner))
)
(define-read-only (get-total-supply)
    (ok (var-get total-supply))
)
(define-read-only (get-balance (who principal))
    (ok (default-to u0 (get balance (map-get? balances { who: who }))))
)
(define-read-only (get-token-info)
    {
        name: token-name,
        symbol: token-symbol,
        decimals: token-decimals,
    }
)
(define-read-only (get-price)
    (ok (var-get price-per-token))
)

(define-private (is-owner (who principal))
    (is-eq who (var-get owner))
)

(define-public (set-price (new uint))
    (begin
        (if (is-owner tx-sender)
            (begin
                (var-set price-per-token new)
                (ok true)
            )
            ERR-NOT-AUTHORIZED
        )
    )
)

(define-private (credit
        (to principal)
        (amount uint)
    )
    (let ((cur (default-to u0 (get balance (map-get? balances { who: to })))))
        (map-set balances { who: to } { balance: (+ cur amount) })
        true
    )
)

(define-private (debit
        (from principal)
        (amount uint)
    )
    (let ((cur (default-to u0 (get balance (map-get? balances { who: from })))))
        (if (< cur amount)
            ERR-INSUFFICIENT-FUNDS
            (begin
                (map-set balances { who: from } { balance: (- cur amount) })
                (ok true)
            )
        )
    )
)

;; Public mint via purchase
(define-public (buy-rare (amount uint))
    (let (
            (price (var-get price-per-token))
            (pay (* amount price))
        )
        (if (or (is-eq amount u0) (> pay u340282366920938463463374607431768211455)) ;; u128 max guard
            ERR-BAD-ARGS
            (begin
                (try! (stx-transfer? pay tx-sender (var-get owner)))
                (var-set total-supply (+ (var-get total-supply) amount))
                (credit tx-sender amount)
                (ok amount)
            )
        )
    )
)

;; Burn from the caller
(define-public (burn-from-sender (amount uint))
    (if (is-eq amount u0)
        ERR-BAD-ARGS
        (begin
            (try! (debit tx-sender amount))
            (var-set total-supply (- (var-get total-supply) amount))
            (ok amount)
        )
    )
)
