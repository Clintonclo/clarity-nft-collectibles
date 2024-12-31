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

;; Transfers collectible ownership between principals
(define-public (transfer-collectible (token-id uint) (from principal) (to principal))
    (begin
        (asserts! (is-eq to tx-sender) error-not-collectible-owner)
        (asserts! (not (is-collectible-burned token-id)) error-already-burned)
        (let ((current-owner (unwrap! (nft-get-owner? collectible-token token-id) error-not-collectible-owner)))
            (asserts! (is-eq current-owner from) error-not-collectible-owner)
            (try! (nft-transfer? collectible-token token-id from to))
            (ok true))))

;; Updates the metadata URI for a collectible
(define-public (modify-collectible-uri (token-id uint) (updated-uri (string-ascii 256)))
    (let ((owner (unwrap! (nft-get-owner? collectible-token token-id) error-collectible-not-found)))
        (asserts! (is-eq owner tx-sender) error-uri-update-not-allowed)
        (asserts! (check-uri-validity updated-uri) error-invalid-uri)
        (map-set collectible-uri token-id updated-uri)
        (ok true)))

;; =================================================================
;; Read-Only Functions
;; =================================================================

;; Retrieves the metadata URI for a collectible
(define-read-only (get-collectible-uri (token-id uint))
    (ok (map-get? collectible-uri token-id)))

;; Gets the current owner of a collectible
(define-read-only (fetch-owner (token-id uint))
    (ok (nft-get-owner? collectible-token token-id)))

;; Returns the latest minted collectible ID
(define-read-only (get-current-collectible-id)
    (ok (var-get current-collectible-id)))

;; Checks if a collectible has been burned
(define-read-only (has-been-burned (token-id uint))
    (ok (is-collectible-burned token-id)))

;; Returns the burned status of a collectible (true if burned, false otherwise)
(define-read-only (is-collectible-burned-status (token-id uint))
    (ok (is-collectible-burned token-id)))

;; Retrieves the metadata URI for a specific collectible, can be used for faster access without extra data
(define-read-only (get-specific-uri (token-id uint))
    (ok (map-get? collectible-uri token-id)))

;; Retrieves the total number of collectibles minted
(define-read-only (get-total-collectibles)
    (ok (var-get current-collectible-id)))

;; Lists collectibles metadata URIs within a specified range of collectible IDs
(define-read-only (list-collectibles-metadata (start-id uint) (count uint))
    (ok (map id-details (unwrap-panic (as-max-len? (fetch-collectibles start-id count) u50)))))

;; Checks if a collectible exists based on its token ID
(define-read-only (collectible-exists? (token-id uint))
    (ok (is-some (map-get? collectible-uri token-id))))

;; Retrieves batch information for a specific collectible ID
(define-read-only (get-batch-info (token-id uint))
    (ok (map-get? batch-info token-id)))

;; Lists collectibles within a specified range
(define-read-only (list-batch-collectibles (start-id uint) (count uint))
    (ok (map id-details (unwrap-panic (as-max-len? (fetch-collectibles start-id count) u50)))))

;; Helper function to create collectible details object
(define-private (id-details (id uint))
    {
        collectible-id: id,
        uri: (unwrap-panic (get-collectible-uri id)),
        owner: (unwrap-panic (fetch-owner id)),
        burned: (unwrap-panic (has-been-burned id))
    })

;; Checks if a collectible exists based on its token ID
(define-read-only (check-collectible-existence (token-id uint))
    (ok (is-some (map-get? collectible-uri token-id))))

;; Retrieves full metadata of a collectible by its token ID
(define-read-only (get-collectible-metadata-details (token-id uint))
    (let ((uri (map-get? collectible-uri token-id))
          (owner (nft-get-owner? collectible-token token-id))
          (burned (is-collectible-burned token-id)))
        (ok {collectible-id: token-id, uri: uri, owner: owner, burned: burned})))

(define-read-only (get-collectible-metadata (token-id uint))
(ok (map-get? collectible-uri token-id)))

;; Helper function to generate sequence of collectible IDs
(define-private (fetch-collectibles (start uint) (count uint))
    (map + 
        (list start) 
        (build-sequence count)))

;; Helper function to build numeric sequence
(define-private (build-sequence (num uint))
    (map - (list num)))

;; =================================================================
;; Contract Initialization
;; =================================================================

(begin
    (var-set current-collectible-id u0))