;; Healthcare Cost Transparency Contract
;; Provides clear pricing information for medical procedures and services

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-INVALID-INPUT (err u501))
(define-constant ERR-PROCEDURE-NOT-FOUND (err u502))
(define-constant ERR-PRICE-NOT-FOUND (err u503))

;; Data Variables
(define-data-var next-procedure-id uint u1)
(define-data-var next-price-id uint u1)

;; Data Maps
(define-map medical-procedures
  { procedure-id: uint }
  {
    name: (string-ascii 100),
    category: (string-ascii 50),
    description: (string-ascii 300),
    complexity-level: uint,
    standard-duration: uint,
    active: bool,
    created-at: uint
  }
)

(define-map procedure-prices
  { price-id: uint }
  {
    facility-id: uint,
    procedure-id: uint,
    base-price: uint,
    insurance-price: uint,
    cash-price: uint,
    emergency-price: uint,
    effective-date: uint,
    expiry-date: uint,
    active: bool
  }
)

(define-map cost-analytics
  { facility-id: uint, procedure-id: uint, month: uint, year: uint }
  {
    total-procedures: uint,
    average-cost: uint,
    price-variance: uint,
    insurance-coverage-rate: uint,
    patient-satisfaction: uint,
    cost-effectiveness-score: uint
  }
)

(define-map price-comparisons
  { procedure-id: uint, region: (string-ascii 50) }
  {
    min-price: uint,
    max-price: uint,
    average-price: uint,
    median-price: uint,
    facility-count: uint,
    last-updated: uint
  }
)

(define-map authorized-facilities
  { facility-id: uint }
  { name: (string-ascii 100), region: (string-ascii 50), active: bool }
)

(define-map pricing-administrators
  { admin: principal }
  { facility-id: uint, active: bool }
)

;; Authorization Functions
(define-public (register-facility (facility-id uint) (name (string-ascii 100)) (region (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len region) u0) ERR-INVALID-INPUT)
    (ok (map-set authorized-facilities
      { facility-id: facility-id }
      { name: name, region: region, active: true }))
  )
)

(define-public (authorize-pricing-admin (admin principal) (facility-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? authorized-facilities { facility-id: facility-id })) ERR-INVALID-INPUT)
    (ok (map-set pricing-administrators
      { admin: admin }
      { facility-id: facility-id, active: true }))
  )
)

;; Procedure Management
(define-public (create-medical-procedure
  (name (string-ascii 100))
  (category (string-ascii 50))
  (description (string-ascii 300))
  (complexity-level uint)
  (standard-duration uint))
  (let ((procedure-id (var-get next-procedure-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (and (>= complexity-level u1) (<= complexity-level u5)) ERR-INVALID-INPUT)
    (asserts! (> standard-duration u0) ERR-INVALID-INPUT)

    (map-set medical-procedures
      { procedure-id: procedure-id }
      {
        name: name,
        category: category,
        description: description,
        complexity-level: complexity-level,
        standard-duration: standard-duration,
        active: true,
        created-at: block-height
      }
    )
    (var-set next-procedure-id (+ procedure-id u1))
    (ok procedure-id)
  )
)

;; Price Management
(define-public (set-procedure-price
  (facility-id uint)
  (procedure-id uint)
  (base-price uint)
  (insurance-price uint)
  (cash-price uint)
  (emergency-price uint)
  (effective-date uint)
  (expiry-date uint))
  (let
    (
      (price-id (var-get next-price-id))
      (admin-info (map-get? pricing-administrators { admin: tx-sender }))
    )
    (asserts! (is-some admin-info) ERR-NOT-AUTHORIZED)
    (asserts! (get active (unwrap! admin-info ERR-NOT-AUTHORIZED)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get facility-id (unwrap! admin-info ERR-NOT-AUTHORIZED)) facility-id) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? medical-procedures { procedure-id: procedure-id })) ERR-PROCEDURE-NOT-FOUND)
    (asserts! (> base-price u0) ERR-INVALID-INPUT)
    (asserts! (> insurance-price u0) ERR-INVALID-INPUT)
    (asserts! (> cash-price u0) ERR-INVALID-INPUT)
    (asserts! (> emergency-price u0) ERR-INVALID-INPUT)
    (asserts! (< effective-date expiry-date) ERR-INVALID-INPUT)

    (map-set procedure-prices
      { price-id: price-id }
      {
        facility-id: facility-id,
        procedure-id: procedure-id,
        base-price: base-price,
        insurance-price: insurance-price,
        cash-price: cash-price,
        emergency-price: emergency-price,
        effective-date: effective-date,
        expiry-date: expiry-date,
        active: true
      }
    )
    (var-set next-price-id (+ price-id u1))
    (ok price-id)
  )
)

;; Cost Analytics Update
(define-public (update-cost-analytics
  (facility-id uint)
  (procedure-id uint)
  (month uint)
  (year uint)
  (total-procedures uint)
  (average-cost uint)
  (price-variance uint)
  (insurance-coverage-rate uint)
  (patient-satisfaction uint)
  (cost-effectiveness-score uint))
  (let ((admin-info (map-get? pricing-administrators { admin: tx-sender })))
    (asserts! (is-some admin-info) ERR-NOT-AUTHORIZED)
    (asserts! (get active (unwrap! admin-info ERR-NOT-AUTHORIZED)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get facility-id (unwrap! admin-info ERR-NOT-AUTHORIZED)) facility-id) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= month u1) (<= month u12)) ERR-INVALID-INPUT)
    (asserts! (> year u2020) ERR-INVALID-INPUT)
    (asserts! (> total-procedures u0) ERR-INVALID-INPUT)
    (asserts! (> average-cost u0) ERR-INVALID-INPUT)
    (asserts! (<= insurance-coverage-rate u100) ERR-INVALID-INPUT)
    (asserts! (and (>= patient-satisfaction u1) (<= patient-satisfaction u5)) ERR-INVALID-INPUT)
    (asserts! (<= cost-effectiveness-score u100) ERR-INVALID-INPUT)

    (map-set cost-analytics
      { facility-id: facility-id, procedure-id: procedure-id, month: month, year: year }
      {
        total-procedures: total-procedures,
        average-cost: average-cost,
        price-variance: price-variance,
        insurance-coverage-rate: insurance-coverage-rate,
        patient-satisfaction: patient-satisfaction,
        cost-effectiveness-score: cost-effectiveness-score
      }
    )
    (ok true)
  )
)

;; Price Comparison Update
(define-public (update-price-comparison
  (procedure-id uint)
  (region (string-ascii 50))
  (min-price uint)
  (max-price uint)
  (average-price uint)
  (median-price uint)
  (facility-count uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? medical-procedures { procedure-id: procedure-id })) ERR-PROCEDURE-NOT-FOUND)
    (asserts! (> min-price u0) ERR-INVALID-INPUT)
    (asserts! (>= max-price min-price) ERR-INVALID-INPUT)
    (asserts! (and (>= average-price min-price) (<= average-price max-price)) ERR-INVALID-INPUT)
    (asserts! (and (>= median-price min-price) (<= median-price max-price)) ERR-INVALID-INPUT)
    (asserts! (> facility-count u0) ERR-INVALID-INPUT)

    (map-set price-comparisons
      { procedure-id: procedure-id, region: region }
      {
        min-price: min-price,
        max-price: max-price,
        average-price: average-price,
        median-price: median-price,
        facility-count: facility-count,
        last-updated: block-height
      }
    )
    (ok true)
  )
)

;; Price Lookup Functions
(define-read-only (get-current-price (facility-id uint) (procedure-id uint))
  (let ((current-block block-height))
    (fold check-active-price
      (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) ;; Check up to 10 recent prices
      none)
  )
)

(define-private (check-active-price (price-id uint) (current-result (optional (tuple (price-id uint) (base-price uint) (insurance-price uint) (cash-price uint) (emergency-price uint)))))
  (if (is-some current-result)
    current-result
    (match (map-get? procedure-prices { price-id: price-id })
      price-data
        (if (and (get active price-data)
                 (<= (get effective-date price-data) block-height)
                 (> (get expiry-date price-data) block-height))
          (some {
            price-id: price-id,
            base-price: (get base-price price-data),
            insurance-price: (get insurance-price price-data),
            cash-price: (get cash-price price-data),
            emergency-price: (get emergency-price price-data)
          })
          none)
      none)
  )
)

;; Read-only Functions
(define-read-only (get-medical-procedure (procedure-id uint))
  (map-get? medical-procedures { procedure-id: procedure-id })
)

(define-read-only (get-procedure-price (price-id uint))
  (map-get? procedure-prices { price-id: price-id })
)

(define-read-only (get-cost-analytics (facility-id uint) (procedure-id uint) (month uint) (year uint))
  (map-get? cost-analytics { facility-id: facility-id, procedure-id: procedure-id, month: month, year: year })
)

(define-read-only (get-price-comparison (procedure-id uint) (region (string-ascii 50)))
  (map-get? price-comparisons { procedure-id: procedure-id, region: region })
)

(define-read-only (is-facility-authorized (facility-id uint))
  (match (map-get? authorized-facilities { facility-id: facility-id })
    facility-info (get active facility-info)
    false
  )
)

(define-read-only (is-pricing-admin-authorized (admin principal))
  (match (map-get? pricing-administrators { admin: admin })
    admin-info (get active admin-info)
    false
  )
)

(define-read-only (get-next-procedure-id)
  (var-get next-procedure-id)
)

(define-read-only (get-next-price-id)
  (var-get next-price-id)
)
