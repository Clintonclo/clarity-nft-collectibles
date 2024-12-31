;; digital-collectibles.clar
;; =================================================================
;; A Clarity smart contract for managing digital collectible NFTs (Non-Fungible Tokens).
;; This contract provides functionality for minting, burning, transferring, and batch processing of NFTs, 
;; with the ability to manage metadata URIs for each collectible. 
;; Key operations include:
;; - Minting a single or batch of collectibles
;; - Burning collectibles (permanent destruction)
;; - Transferring collectible ownership
;; - Updating collectible metadata URI
;; - Retrieving collectible details, including URI and owner information
;;
;; Features:
;; - Administrative control for minting and burning actions
;; - Batch minting with a configurable limit
;; - Supports metadata URI validation and updates
;; - Error handling for various edge cases (e.g., invalid URI, collectible not found)
;;=================================================================

;; =================================================================
;; Constants
;; =================================================================

;; Administrative Constants
(define-constant platform-admin tx-sender)
(define-constant max-collectible-batch u50)  ;; Maximum number of NFTs that can be minted in a single batch

;; Error Codes
(define-constant error-admin-only (err u200))           ;; Only admin can perform this operation
(define-constant error-not-collectible-owner (err u201)) ;; User does not own the collectible
(define-constant error-collectible-exists (err u202))    ;; Collectible ID already exists
(define-constant error-collectible-not-found (err u203)) ;; Collectible ID does not exist
(define-constant error-invalid-uri (err u204))           ;; URI string is invalid or empty
(define-constant error-burn-failed (err u205))           ;; Failed to burn the collectible
(define-constant error-already-burned (err u206))        ;; Collectible has already been burned
(define-constant error-uri-update-not-allowed (err u207)) ;; Not authorized to update URI
(define-constant error-batch-size-limit (err u208))      ;; Batch size exceeds maximum limit
(define-constant error-batch-mint-failed (err u209))     ;; Failed to mint batch of collectibles

;; =================================================================
;; Data Variables and NFT Definitions
;; =================================================================

;; NFT definition for the collectible tokens
(define-non-fungible-token collectible-token uint)

;; Tracks the latest minted collectible ID
(define-data-var current-collectible-id uint u0)

;; =================================================================
;; Data Maps
;; =================================================================

;; Stores metadata URI for each collectible
(define-map collectible-uri uint (string-ascii 256))

;; Tracks burned status of collectibles
(define-map burned-collectibles uint bool)

;; Stores additional batch information
(define-map batch-info uint (string-ascii 256))

;; =================================================================
;; Private Helper Functions
;; =================================================================

;; Verifies if a principal owns a specific collectible
(define-private (verify-collectible-owner (token-id uint) (owner principal))
    (is-eq owner (unwrap! (nft-get-owner? collectible-token token-id) false)))

;; Validates URI string length and format
(define-private (check-uri-validity (uri (string-ascii 256)))
    (let ((uri-len (len uri)))
        (and (>= uri-len u1)
             (<= uri-len u256))))

;; Checks if a collectible has been burned
(define-private (is-collectible-burned (token-id uint))
    (default-to false (map-get? burned-collectibles token-id)))

;; Internal function to mint a single collectible
(define-private (mint-collectible (uri (string-ascii 256)))
    (let ((new-id (+ (var-get current-collectible-id) u1)))
        (asserts! (check-uri-validity uri) error-invalid-uri)
        (try! (nft-mint? collectible-token new-id tx-sender))
        (map-set collectible-uri new-id uri)
        (var-set current-collectible-id new-id)
        (ok new-id)))

;; =================================================================
;; Public Functions
;; =================================================================

;; Creates a single collectible with metadata URI
(define-public (create-collectible (uri (string-ascii 256)))
    (begin
        (asserts! (is-eq tx-sender platform-admin) error-admin-only)
        (asserts! (check-uri-validity uri) error-invalid-uri)
        (mint-collectible uri)))

;; Creates multiple collectibles in a single transaction
(define-public (batch-create (uris (list 50 (string-ascii 256))))
    (let ((batch-size (len uris)))
        (begin
            (asserts! (is-eq tx-sender platform-admin) error-admin-only)
            (asserts! (<= batch-size max-collectible-batch) error-batch-size-limit)
            (asserts! (> batch-size u0) error-batch-size-limit)
            (ok (fold process-batch-mint uris (list)))
        )))

;; Helper function for batch minting process
(define-private (process-batch-mint (uri (string-ascii 256)) (previous-minted (list 50 uint)))
    (match (mint-collectible uri)
        minted-id (unwrap-panic (as-max-len? (append previous-minted minted-id) u50))
        err previous-minted))

;; Burns (permanently destroys) a collectible
(define-public (burn-collectible (token-id uint))
    (let ((owner (unwrap! (nft-get-owner? collectible-token token-id) error-collectible-not-found)))
        (asserts! (is-eq tx-sender owner) error-not-collectible-owner)
        (asserts! (not (is-collectible-burned token-id)) error-already-burned)
        (try! (nft-burn? collectible-token token-id owner))
        (map-set burned-collectibles token-id true)
        (ok true)))
