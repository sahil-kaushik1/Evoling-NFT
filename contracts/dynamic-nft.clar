;; Dynamic 3-stage NFT with SVGs
;; - Stage 1: base after purchase
;; - Stage 2: after 3 recorded activities
;; - Stage 3: after 10 recorded activities OR by burning a rare token to instantly evolve 1 stage

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-NOT-OWNER (err u101))
(define-constant ERR-TOKEN-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-OWN-NFT (err u103))
(define-constant ERR-MAX-STAGE (err u104))
(define-constant ERR-BAD-ARGS (err u105))

(define-data-var owner principal tx-sender)
(define-data-var next-id uint u1)
(define-data-var total-supply uint u0)
(define-data-var price-per-nft uint u2000000) ;; 2 STX

(define-constant STAGE1 u1)
(define-constant STAGE2 u2)
(define-constant STAGE3 u3)

(define-constant THRESHOLD-2 u3)
(define-constant THRESHOLD-3 u10)

(define-map owners
  { id: uint }
  { who: principal }
)
(define-map stages
  { id: uint }
  { stage: uint }
)
(define-map primary-token
  { who: principal }
  { id: uint }
)
(define-map tx-count
  { who: principal }
  { count: uint }
)

;; Basic owner check
(define-private (is-owner (who principal))
  (is-eq who (var-get owner))
)

(define-read-only (get-owner)
  (ok (var-get owner))
)
(define-read-only (get-total-supply)
  (ok (var-get total-supply))
)
(define-read-only (get-price)
  (ok (var-get price-per-nft))
)

(define-read-only (get-owner-of (token-id uint))
  (match (map-get? owners { id: token-id })
    owner-rec (ok (get who owner-rec))
    ERR-TOKEN-NOT-FOUND
  )
)

(define-read-only (get-token-stage (token-id uint))
  (ok (default-to u0 (get stage (map-get? stages { id: token-id }))))
)

(define-read-only (get-user-token (who principal))
  (ok (get id (default-to { id: u0 } (map-get? primary-token { who: who }))))
)

(define-read-only (get-user-tx-count (who principal))
  (ok (default-to u0 (get count (map-get? tx-count { who: who }))))
)

(define-public (set-price (new uint))
  (if (is-owner tx-sender)
    (begin
      (var-set price-per-nft new)
      (ok true)
    )
    ERR-NOT-AUTHORIZED
  )
)

;; Internal evolve helper
(define-private (evolve-by-one (token-id uint))
  (let ((cur (default-to u0 (get stage (map-get? stages { id: token-id })))))
    (if (is-eq cur STAGE3)
      ERR-MAX-STAGE
      (begin
        (map-set stages { id: token-id } { stage: (+ cur u1) })
        (ok (+ cur u1))
      )
    )
  )
)

(define-private (check-and-evolve
    (who principal)
    (token-id uint)
  )
  (let (
      (cnt (default-to u0 (get count (map-get? tx-count { who: who }))))
      (cur (default-to STAGE1 (get stage (map-get? stages { id: token-id }))))
    )
    (if (and (< cur STAGE3) (>= cnt THRESHOLD-3))
      ;; If eligible for stage 3, set it and we're done.
      (map-set stages { id: token-id } { stage: STAGE3 })
      ;; Otherwise, check if eligible for stage 2.
      (if (and (< cur STAGE2) (>= cnt THRESHOLD-2))
        (map-set stages { id: token-id } { stage: STAGE2 })
        ;; Do nothing if no thresholds are met.
        false
      )
    )
  )
)

;; Purchase + mint a new NFT at Stage 1
(define-public (buy-nft)
  (let (
      (existing (default-to u0 (get id (map-get? primary-token { who: tx-sender }))))
      (price (var-get price-per-nft))
      (new-id (var-get next-id))
    )
    (if (not (is-eq existing u0))
      ERR-ALREADY-OWN-NFT
      (begin
        (try! (stx-transfer? price tx-sender (var-get owner)))
        (map-set owners { id: new-id } { who: tx-sender })
        (map-set stages { id: new-id } { stage: STAGE1 })
        (map-set primary-token { who: tx-sender } { id: new-id })
        (var-set total-supply (+ (var-get total-supply) u1))
        (var-set next-id (+ new-id u1))
        (ok new-id)
      )
    )
  )
)

;; Record a user activity and auto-evolve if thresholds met
(define-public (record-activity)
  (let (
      (cur (default-to u0 (get count (map-get? tx-count { who: tx-sender }))))
      (tid (default-to u0 (get id (map-get? primary-token { who: tx-sender }))))
    )
    (if (is-eq tid u0)
      ERR-TOKEN-NOT-FOUND
      (begin
        (map-set tx-count { who: tx-sender } { count: (+ cur u1) })
        (check-and-evolve tx-sender tid)
        (ok (+ cur u1))
      )
    )
  )
)

;; Force evolve by burning one rare token from caller
(define-public (evolve-via-rare)
  (let ((tid (default-to u0 (get id (map-get? primary-token { who: tx-sender })))))
    (if (is-eq tid u0)
      ERR-TOKEN-NOT-FOUND
      (begin
        (try! (contract-call? .rare-token burn-from-sender u1))
        (try! (evolve-by-one tid))
        (ok true)
      )
    )
  )
)
(define-public (transfer
    (token-id uint)
    (recipient principal)
  )
  (let ((owner-record (map-get? owners { id: token-id })))
    (if (is-none owner-record)
      ERR-TOKEN-NOT-FOUND
      (let (
          (cur-owner (get who (unwrap-panic owner-record)))
          (rec-existing (default-to u0 (get id (map-get? primary-token { who: recipient }))))
        )
        (if (not (is-eq cur-owner tx-sender))
          ERR-NOT-OWNER
          (if (not (is-eq rec-existing u0))
            ERR-ALREADY-OWN-NFT
            (begin
              (map-set owners { id: token-id } { who: recipient })
              (map-set primary-token { who: recipient } { id: token-id })
              (map-delete primary-token { who: tx-sender })
              (ok true)
            )
          )
        )
      )
    )
  )
)

;; SVGs and metadata
;; BEGIN_SVG_1
(define-constant SVG-1 "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><rect width='100' height='100' fill='#EFB614'/><text x='50' y='55' font-size='14' text-anchor='middle' fill='#000'>Stage 1</text></svg>")
;; END_SVG_1
;; BEGIN_SVG_2
(define-constant SVG-2 "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><rect width='100' height='100' fill='#FF3E63'/><text x='50' y='55' font-size='14' text-anchor='middle' fill='#fff'>Stage 2</text></svg>")
;; END_SVG_2
;; BEGIN_SVG_3
(define-constant SVG-3 "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><rect width='100' height='100' fill='#FF9A2C'/><text x='50' y='55' font-size='14' text-anchor='middle' fill='#000'>Stage 3</text></svg>")
;; END_SVG_3

(define-read-only (get-token-uri (token-id uint))
  (match (map-get? stages { id: token-id })
    s (let ((stage (get stage s)))
      (ok (concat "data:image/svg+xml;utf8,"
        (if (is-eq stage STAGE1)
          SVG-1
          (if (is-eq stage STAGE2)
            SVG-2
            SVG-3
          )
        )))
    )
    ERR-TOKEN-NOT-FOUND
  )
)
