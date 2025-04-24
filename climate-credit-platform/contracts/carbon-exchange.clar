;; Carbon Credit Trading Platform
;; A comprehensive marketplace for tokenized carbon credits with robust validation, 
;; transparent trading mechanisms, and enhanced metadata tracking

;; Constants
(define-constant CONTRACT-ADMIN tx-sender)
(define-constant ERR-ADMIN-ONLY (err u100))
(define-constant ERR-BALANCE-TOO-LOW (err u101))
(define-constant ERR-ZERO-OR-NEGATIVE-PRICE (err u102))
(define-constant ERR-LISTING-DOES-NOT-EXIST (err u103))
(define-constant ERR-PERMISSION-DENIED (err u104))
(define-constant ERR-INVALID-CREDIT-DATA (err u105))
(define-constant ERR-YEAR-OUT-OF-RANGE (err u106))
(define-constant ERR-UNKNOWN-VERIFICATION-STANDARD (err u107))
(define-constant ERR-UNRECOGNIZED-PROJECT-TYPE (err u108))
(define-constant ERR-LISTING-ALREADY-EXISTS (err u109))
(define-constant ERR-LISTING-INACTIVE (err u110))

;; Data Structures
;; Enhanced storage for carbon credits with detailed metadata and ownership tracking

;; Track user credit holdings
(define-map user-credit-holdings 
  { holder: principal } 
  { credit-amount: uint }
)

;; Store detailed information about each credit type
(define-map carbon-credit-details 
  { credit-identifier: uint } 
  { 
    credit-issuer: principal,  
    production-year: uint, 
    verification-protocol: (string-ascii 64), 
    environmental-initiative-category: (string-ascii 64), 
    total-issued-amount: uint 
  }
)

;; Track marketplace listings
(define-map market-listings 
  { market-listing-id: uint } 
  {
    credit-owner: principal, 
    credit-identifier: uint, 
    credit-quantity: uint, 
    unit-price: uint, 
    is-available: bool 
  }
)

;; Tracking variables for unique identifiers
(define-data-var credit-id-counter uint u1) 
(define-data-var listing-id-counter uint u1) 

;; Read-only functions
;; Query functions to retrieve marketplace data

;; Get a user's credit balance
(define-read-only (get-user-balance (holder principal))
  (default-to { credit-amount: u0 }
    (map-get? user-credit-holdings { holder: holder }))
)

;; Retrieve metadata for a specific credit type
(define-read-only (get-credit-metadata (credit-identifier uint))
  (map-get? carbon-credit-details { credit-identifier: credit-identifier })
)

;; Get details about a specific marketplace listing
(define-read-only (get-market-listing (market-listing-id uint))
  (map-get? market-listings { market-listing-id: market-listing-id })
)

;; Public functions for marketplace interaction

;; Create a new listing to sell carbon credits
(define-public (create-market-listing (credit-identifier uint) 
                             (credit-quantity uint) 
                             (unit-price uint))
  (let (
    (new-listing-id (var-get listing-id-counter))
    (seller-available-balance (get credit-amount (get-user-balance tx-sender)))
  )
    ;; Validate all inputs
    (asserts! (> credit-quantity u0) ERR-INVALID-CREDIT-DATA)
    (asserts! (> unit-price u0) ERR-ZERO-OR-NEGATIVE-PRICE)
    (asserts! (>= seller-available-balance credit-quantity) ERR-BALANCE-TOO-LOW)
    (asserts! (is-some (get-credit-metadata credit-identifier)) ERR-INVALID-CREDIT-DATA)

    ;; Create the new listing
    (map-set market-listings
      { market-listing-id: new-listing-id }
      {
        credit-owner: tx-sender,
        credit-identifier: credit-identifier,
        credit-quantity: credit-quantity,
        unit-price: unit-price,
        is-available: true
      }
    )
    ;; Update the listing counter
    (var-set listing-id-counter (+ new-listing-id u1))
    (ok new-listing-id)
  )
)

;; Remove a listing from the marketplace
(define-public (remove-market-listing (market-listing-id uint))
  (let ((listing-details (unwrap! (get-market-listing market-listing-id) ERR-LISTING-DOES-NOT-EXIST)))
    ;; Security checks
    (asserts! (is-eq tx-sender (get credit-owner listing-details)) ERR-PERMISSION-DENIED)
    (asserts! (get is-available listing-details) ERR-LISTING-DOES-NOT-EXIST)

    ;; Update listing status
    (map-set market-listings
      { market-listing-id: market-listing-id }
      (merge listing-details { is-available: false })
    )
    (ok true)
  )
)

;; Execute a purchase transaction for carbon credits
(define-public (buy-carbon-credits (market-listing-id uint))
  (let (
    (listing-details (unwrap! (get-market-listing market-listing-id) ERR-LISTING-DOES-NOT-EXIST))
    (total-purchase-cost (* (get unit-price listing-details) (get credit-quantity listing-details)))
  )
    ;; Verify listing availability
    (asserts! (get is-available listing-details) ERR-LISTING-DOES-NOT-EXIST)

    ;; Process payment
    (try! (stx-transfer? total-purchase-cost tx-sender (get credit-owner listing-details)))

    ;; Update seller balance
    (map-set user-credit-holdings
      { holder: (get credit-owner listing-details) }
      { credit-amount: (- (get credit-amount (get-user-balance (get credit-owner listing-details))) 
                          (get credit-quantity listing-details)) }
    )
    
    ;; Update buyer balance
    (map-set user-credit-holdings
      { holder: tx-sender }
      { credit-amount: (+ (get credit-amount (get-user-balance tx-sender)) 
                          (get credit-quantity listing-details)) }
    )

    ;; Close the listing
    (map-set market-listings
      { market-listing-id: market-listing-id }
      (merge listing-details { is-available: false })
    )
    (ok true)
  )
)

;; Transfer credits directly between users
(define-public (transfer-carbon-credits (recipient principal) (credit-amount uint))
  (let ((sender-available-balance (get credit-amount (get-user-balance tx-sender))))
    ;; Validate transfer parameters
    (asserts! (>= sender-available-balance credit-amount) ERR-BALANCE-TOO-LOW)
    (asserts! (is-recipient-authorized? recipient) ERR-PERMISSION-DENIED)

    ;; Update sender balance
    (map-set user-credit-holdings
      { holder: tx-sender }
      { credit-amount: (- sender-available-balance credit-amount) }
    )
    
    ;; Update recipient balance
    (map-set user-credit-holdings
      { holder: recipient }
      { credit-amount: (+ (get credit-amount (get-user-balance recipient)) credit-amount) }
    )
    (ok true)
  )
)

;; Authorization helper function
(define-private (is-recipient-authorized? (potential-recipient principal))
  ;; Authorization logic could be expanded here
  true
)

;; Modify an existing market listing
(define-public (modify-market-listing (market-listing-id uint) 
                                    (updated-quantity uint) 
                                    (updated-price uint))
  (let ((listing-details (unwrap! (get-market-listing market-listing-id) ERR-LISTING-DOES-NOT-EXIST)))
    ;; Validate permissions and listing state
    (asserts! (is-eq tx-sender (get credit-owner listing-details)) ERR-PERMISSION-DENIED)
    (asserts! (get is-available listing-details) ERR-LISTING-INACTIVE)
    (asserts! (> updated-quantity u0) ERR-INVALID-CREDIT-DATA)
    (asserts! (> updated-price u0) ERR-ZERO-OR-NEGATIVE-PRICE)

    ;; Update the listing with new values
    (map-set market-listings
      { market-listing-id: market-listing-id }
      (merge listing-details 
        { 
          credit-quantity: updated-quantity,
          unit-price: updated-price
        })
    )
    (ok true)
  )
)

;; Report issues with specific carbon credits
(define-public (submit-credit-issue-report (credit-identifier uint) 
                                        (issue-description (string-ascii 256)))
  (let ((credit-info (get-credit-metadata credit-identifier)))
    (asserts! (is-some credit-info) ERR-INVALID-CREDIT-DATA)

    ;; Log the report for future implementation
    (print issue-description)
    (ok true)
  )
)

;; Create new carbon credits (admin only)
(define-public (issue-new-carbon-credits (credit-amount uint) 
                                      (production-year uint)
                                      (verification-protocol (string-ascii 64))
                                      (environmental-initiative-category (string-ascii 64)))
  (let ((new-credit-id (var-get credit-id-counter)))
    ;; Admin authorization check
    (if (is-eq tx-sender CONTRACT-ADMIN)
      (begin
        ;; Record the credit metadata
        (map-set carbon-credit-details
          { credit-identifier: new-credit-id }
          {
            credit-issuer: tx-sender,
            production-year: production-year,
            verification-protocol: verification-protocol,
            environmental-initiative-category: environmental-initiative-category,
            total-issued-amount: credit-amount
          }
        )
        ;; Assign credits to the issuer
        (map-set user-credit-holdings
          { holder: tx-sender }
          { credit-amount: (+ (get credit-amount (get-user-balance tx-sender)) credit-amount) }
        )
        ;; Update credit counter
        (var-set credit-id-counter (+ new-credit-id u1))
        (ok new-credit-id)
      )
      ERR-ADMIN-ONLY
    )
  )
)