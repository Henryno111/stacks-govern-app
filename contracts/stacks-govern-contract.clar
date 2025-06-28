
;; Stacks-dao-contract
;; A DAO governance contract that allows members to create, vote on, and execute proposals

;; constants
;;
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROPOSAL-EXISTS (err u101))
(define-constant ERR-PROPOSAL-EXPIRED (err u102))
(define-constant ERR-PROPOSAL-ACTIVE (err u103))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u104))
(define-constant ERR-ALREADY-VOTED (err u105))
(define-constant ERR-NOT-MEMBER (err u106))
(define-constant ERR-INSUFFICIENT-STAKE (err u107))
(define-constant ERR-QUORUM-NOT-REACHED (err u108))
(define-constant ERR-PROPOSAL-NOT-APPROVED (err u109))

(define-constant PROPOSAL-DURATION u144) ;; ~1 day in blocks (assuming 10 min block time)
(define-constant MINIMUM-STAKE u100000000) ;; 100 STX
(define-constant QUORUM-PERCENTAGE u30) ;; 30% of total members must vote

;; data maps and vars
;;
(define-map members principal uint)
(define-map proposals
  { proposal-id: uint }
  {
    proposer: principal,
    title: (string-ascii 100),
    description: (string-utf8 500),
    link: (optional (string-ascii 256)),
    created-at-block: uint,
    expires-at-block: uint,
    yes-votes: uint,
    no-votes: uint,
    status: (string-ascii 20), ;; "active", "approved", "rejected", "executed"
    action-contract: (optional principal),
    action-function: (optional (string-ascii 128)),
    action-args: (optional (list 10 (string-utf8 256)))
  }
)

(define-map votes
  { proposal-id: uint, voter: principal }
  { vote: bool }
)

(define-data-var proposal-count uint u0)
(define-data-var total-stake uint u0)
(define-data-var dao-owner principal tx-sender)

;; private functions
;;
(define-private (is-dao-owner)
  (is-eq tx-sender (var-get dao-owner))
)

(define-private (is-member (user principal))
  (> (default-to u0 (map-get? members user)) u0)
)

(define-private (check-proposal-status (proposal-id uint))
  (match (map-get? proposals { proposal-id: proposal-id })
    proposal (let (
      (current-block block-height)
    )
      (if (> current-block (get expires-at-block proposal))
        (if (>= (get yes-votes proposal) (get no-votes proposal))
          "approved"
          "rejected"
        )
        (get status proposal)
      ))
    "not-found"
  )
)

(define-private (calculate-quorum (proposal-id uint))
  (match (map-get? proposals { proposal-id: proposal-id })
    proposal (let (
      (total-votes (+ (get yes-votes proposal) (get no-votes proposal)))
      (quorum-threshold (/ (* (var-get total-stake) QUORUM-PERCENTAGE) u100))
    )
      (>= total-votes quorum-threshold))
    false
  )
)

;; public functions
;;
