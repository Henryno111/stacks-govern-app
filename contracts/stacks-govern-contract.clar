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
(define-public (set-dao-owner (new-owner principal))
  (begin
    (asserts! (is-dao-owner) ERR-NOT-AUTHORIZED)
    (ok (var-set dao-owner new-owner))
  )
)

(define-public (add-member (user principal) (stake uint))
  (begin
    (asserts! (is-dao-owner) ERR-NOT-AUTHORIZED)
    (asserts! (>= stake MINIMUM-STAKE) ERR-INSUFFICIENT-STAKE)
    (map-set members user stake)
    (var-set total-stake (+ (var-get total-stake) stake))
    (ok true)
  )
)

(define-public (remove-member (user principal))
  (let ((stake (default-to u0 (map-get? members user))))
    (asserts! (is-dao-owner) ERR-NOT-AUTHORIZED)
    (asserts! (is-member user) ERR-NOT-MEMBER)
    (map-delete members user)
    (var-set total-stake (- (var-get total-stake) stake))
    (ok true)
  )
)

(define-public (create-proposal (title (string-ascii 100)) (description (string-utf8 500)) 
                               (link (optional (string-ascii 256)))
                               (action-contract (optional principal))
                               (action-function (optional (string-ascii 128)))
                               (action-args (optional (list 10 (string-utf8 256)))))
  (let (
    (proposal-id (+ (var-get proposal-count) u1))
    (current-block block-height)
  )
    (asserts! (is-member tx-sender) ERR-NOT-MEMBER)
    (map-set proposals
      { proposal-id: proposal-id }
      {
        proposer: tx-sender,
        title: title,
        description: description,
        link: link,
        created-at-block: current-block,
        expires-at-block: (+ current-block PROPOSAL-DURATION),
        yes-votes: u0,
        no-votes: u0,
        status: "active",
        action-contract: action-contract,
        action-function: action-function,
        action-args: action-args
      }
    )
    (var-set proposal-count proposal-id)
    (ok proposal-id)
  )
)

(define-public (vote (proposal-id uint) (vote-value bool))
  (let (
    (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR-PROPOSAL-NOT-FOUND))
    (voter-stake (unwrap! (map-get? members tx-sender) ERR-NOT-MEMBER))
    (vote-key { proposal-id: proposal-id, voter: tx-sender })
  )
    (asserts! (is-eq (get status proposal) "active") ERR-PROPOSAL-EXPIRED)
    (asserts! (<= block-height (get expires-at-block proposal)) ERR-PROPOSAL-EXPIRED)
    (asserts! (is-none (map-get? votes vote-key)) ERR-ALREADY-VOTED)
    
    (map-set votes vote-key { vote: vote-value })
    
    (if vote-value
      (map-set proposals { proposal-id: proposal-id }
        (merge proposal { yes-votes: (+ (get yes-votes proposal) voter-stake) })
      )
      (map-set proposals { proposal-id: proposal-id }
        (merge proposal { no-votes: (+ (get no-votes proposal) voter-stake) })
      )
    )
    (ok true)
  )
)

(define-public (execute-proposal (proposal-id uint))
  (let (
    (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR-PROPOSAL-NOT-FOUND))
    (status (check-proposal-status proposal-id))
  )
    (asserts! (is-member tx-sender) ERR-NOT-MEMBER)
    (asserts! (is-eq status "approved") ERR-PROPOSAL-NOT-APPROVED)
    (asserts! (calculate-quorum proposal-id) ERR-QUORUM-NOT-REACHED)
    
    (map-set proposals { proposal-id: proposal-id }
      (merge proposal { status: "executed" })
    )
    (ok true)
  )
)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id })
)

(define-read-only (get-member-stake (member principal))
  (default-to u0 (map-get? members member))
)

(define-read-only (get-total-stake)
  (var-get total-stake)
)

(define-read-only (get-proposal-count)
  (var-get proposal-count)
)

(define-read-only (get-proposal-status (proposal-id uint))
  (check-proposal-status proposal-id)
)
