
// File: contracts/lib/ERC20Events.sol


pragma solidity ^0.8.20;

library ERC20Events {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 amount);
}

// File: contracts/lib/ERC721Events.sol


pragma solidity ^0.8.20;

library ERC721Events {
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 indexed id
  );
  event Transfer(address indexed from, address indexed to, uint256 indexed id);
}

// File: contracts/lib/PackedDoubleEndedQueue.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/DoubleEndedQueue.sol)
// Modified by Pandora Labs to support native packed operations
pragma solidity ^0.8.20;

/**
 * @dev A sequence of items with the ability to efficiently push and pop items (i.e. insert and remove) on both ends of
 * the sequence (called front and back). Among other access patterns, it can be used to implement efficient LIFO and
 * FIFO queues. Storage use is optimized, and all operations are O(1) constant time. This includes {clear}, given that
 * the existing queue contents are left in storage.
 *
 * The struct is called `Uint16Deque`. And is designed for packed uint16 values, though this approach can be
 * extrapolated to different implementations. This data structure can only be used in storage, and not in memory.
 *
 * ```solidity
 * PackedDoubleEndedQueue.Uint16Deque queue;
 * ```
 */
library PackedDoubleEndedQueue {
  uint128 constant SLOT_MASK = (1 << 64) - 1;
  uint128 constant INDEX_MASK = SLOT_MASK << 64;

  uint256 constant SLOT_DATA_MASK = (1 << 16) - 1;

  /**
   * @dev An operation (e.g. {front}) couldn't be completed due to the queue being empty.
   */
  error QueueEmpty();

  /**
   * @dev A push operation couldn't be completed due to the queue being full.
   */
  error QueueFull();

  /**
   * @dev An operation (e.g. {at}) couldn't be completed due to an index being out of bounds.
   */
  error QueueOutOfBounds();

  /**
   * @dev Invalid slot.
   */
  error InvalidSlot();

  /**
   * @dev Indices and slots are 64 bits to fit within a single storage slot.
   *
   * Struct members have an underscore prefix indicating that they are "private" and should not be read or written to
   * directly. Use the functions provided below instead. Modifying the struct manually may violate assumptions and
   * lead to unexpected behavior.
   *
   * The first item is at data[begin] and the last item is at data[end - 1]. This range can wrap around.
   */
  struct Uint16Deque {
    uint64 _beginIndex;
    uint64 _beginSlot;
    uint64 _endIndex;
    uint64 _endSlot;
    mapping(uint64 index => uint256) _data;
  }

  /**
   * @dev Removes the item at the end of the queue and returns it.
   *
   * Reverts with {QueueEmpty} if the queue is empty.
   */
  function popBack(Uint16Deque storage deque) internal returns (uint16 value) {
    unchecked {
      uint64 backIndex = deque._endIndex;
      uint64 backSlot = deque._endSlot;

      if (backIndex == deque._beginIndex && backSlot == deque._beginSlot)
        revert QueueEmpty();

      if (backSlot == 0) {
        --backIndex;
        backSlot = 15;
      } else {
        --backSlot;
      }

      uint256 data = deque._data[backIndex];

      value = _getEntry(data, backSlot);
      deque._data[backIndex] = _setData(data, backSlot, 0);

      deque._endIndex = backIndex;
      deque._endSlot = backSlot;
    }
  }

  /**
   * @dev Inserts an item at the beginning of the queue.
   *
   * Reverts with {QueueFull} if the queue is full.
   */
  function pushFront(Uint16Deque storage deque, uint16 value_) internal {
    unchecked {
      uint64 frontIndex = deque._beginIndex;
      uint64 frontSlot = deque._beginSlot;

      if (frontSlot == 0) {
        --frontIndex;
        frontSlot = 15;
      } else {
        --frontSlot;
      }

      if (frontIndex == deque._endIndex && frontSlot == deque._endSlot)
        revert QueueFull();

      deque._data[frontIndex] = _setData(
        deque._data[frontIndex],
        frontSlot,
        value_
      );
      deque._beginIndex = frontIndex;
      deque._beginSlot = frontSlot;
    }
  }

  /**
   * @dev Return the item at a position in the queue given by `index`, with the first item at 0 and last item at
   * `length(deque) - 1`.
   *
   * Reverts with `QueueOutOfBounds` if the index is out of bounds.
   */
  function at(
    Uint16Deque storage deque,
    uint256 index_
  ) internal view returns (uint16 value) {
    if (index_ >= length(deque) * 16) revert QueueOutOfBounds();

    unchecked {
      return
        _getEntry(
          deque._data[
            deque._beginIndex +
              uint64(deque._beginSlot + (index_ % 16)) /
              16 +
              uint64(index_ / 16)
          ],
          uint64(((deque._beginSlot + index_) % 16))
        );
    }
  }

  /**
   * @dev Returns the number of items in the queue.
   */
  function length(Uint16Deque storage deque) internal view returns (uint256) {
    unchecked {
      return
        (16 - deque._beginSlot) +
        deque._endSlot +
        deque._endIndex *
        16 -
        deque._beginIndex *
        16 -
        16;
    }
  }

  /**
   * @dev Returns true if the queue is empty.
   */
  function empty(Uint16Deque storage deque) internal view returns (bool) {
    return
      deque._endSlot == deque._beginSlot &&
      deque._endIndex == deque._beginIndex;
  }

  function _setData(
    uint256 data_,
    uint64 slot_,
    uint16 value
  ) private pure returns (uint256) {
    return (data_ & (~_getSlotMask(slot_))) + (uint256(value) << (16 * slot_));
  }

  function _getEntry(uint256 data, uint64 slot_) private pure returns (uint16) {
    return uint16((data & _getSlotMask(slot_)) >> (16 * slot_));
  }

  function _getSlotMask(uint64 slot_) private pure returns (uint256) {
    return SLOT_DATA_MASK << (slot_ * 16);
  }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/interfaces/IERC165.sol


// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC165.sol)

pragma solidity ^0.8.20;


// File: contracts/interfaces/IERC404.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


interface IERC404 is IERC165 {
  error NotFound();
  error InvalidTokenId();
  error AlreadyExists();
  error InvalidRecipient();
  error InvalidSender();
  error InvalidSpender();
  error InvalidOperator();
  error UnsafeRecipient();
  error RecipientIsERC721TransferExempt();
  error Unauthorized();
  error InsufficientAllowance();
  error DecimalsTooLow();
  error PermitDeadlineExpired();
  error InvalidSigner();
  error InvalidApproval();
  error OwnedIndexOverflow();
  error MintLimitReached();
  error InvalidExemption();

  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function totalSupply() external view returns (uint256);
  function erc20TotalSupply() external view returns (uint256);
  function erc721TotalSupply() external view returns (uint256);
  function balanceOf(address owner_) external view returns (uint256);
  function erc721BalanceOf(address owner_) external view returns (uint256);
  function erc20BalanceOf(address owner_) external view returns (uint256);
  function erc721TransferExempt(address account_) external view returns (bool);
  function isApprovedForAll(
    address owner_,
    address operator_
  ) external view returns (bool);
  function allowance(
    address owner_,
    address spender_
  ) external view returns (uint256);
  function owned(address owner_) external view returns (uint256[] memory);
  function ownerOf(uint256 id_) external view returns (address erc721Owner);
  function tokenURI(uint256 id_) external view returns (string memory);
  function approve(
    address spender_,
    uint256 valueOrId_
  ) external returns (bool);
  function erc20Approve(
    address spender_,
    uint256 value_
  ) external returns (bool);
  function erc721Approve(address spender_, uint256 id_) external;
  function setApprovalForAll(address operator_, bool approved_) external;
  function transferFrom(
    address from_,
    address to_,
    uint256 valueOrId_
  ) external returns (bool);
  function erc20TransferFrom(
    address from_,
    address to_,
    uint256 value_
  ) external returns (bool);
  function erc721TransferFrom(address from_, address to_, uint256 id_) external;
  function transfer(address to_, uint256 amount_) external returns (bool);
  function getERC721QueueLength() external view returns (uint256);
  function getERC721TokensInQueue(
    uint256 start_,
    uint256 count_
  ) external view returns (uint256[] memory);
  function setSelfERC721TransferExempt(bool state_) external;
  function safeTransferFrom(address from_, address to_, uint256 id_) external;
  function safeTransferFrom(
    address from_,
    address to_,
    uint256 id_,
    bytes calldata data_
  ) external;
  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function permit(
    address owner_,
    address spender_,
    uint256 value_,
    uint256 deadline_,
    uint8 v_,
    bytes32 r_,
    bytes32 s_
  ) external;
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.20;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/interfaces/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC721Receiver.sol)

pragma solidity ^0.8.20;


// File: contracts/ERC404U16.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;







/// @dev This is an optimized ERC404 implementation designed to support smaller collections,
///      with id's up to a maximum of 65535.
abstract contract ERC404U16 is IERC404 {
  using PackedDoubleEndedQueue for PackedDoubleEndedQueue.Uint16Deque;

  /// @dev The queue of ERC-721 tokens stored in the contract.
  PackedDoubleEndedQueue.Uint16Deque private _storedERC721Ids;

  /// @dev Token name
  string public name;

  /// @dev Token symbol
  string public symbol;

  /// @dev Decimals for ERC-20 representation
  uint8 public immutable decimals;

  /// @dev Units for ERC-20 representation
  uint256 public immutable units;

  /// @dev Total supply in ERC-20 representation
  uint256 public totalSupply;

  /// @dev Current mint counter which also represents the highest
  ///      minted id, monotonically increasing to ensure accurate ownership
  uint256 public minted;

  /// @dev Initial chain id for EIP-2612 support
  uint256 internal immutable _INITIAL_CHAIN_ID;

  /// @dev Initial domain separator for EIP-2612 support
  bytes32 internal immutable _INITIAL_DOMAIN_SEPARATOR;

  /// @dev Balance of user in ERC-20 representation
  mapping(address => uint256) public balanceOf;

  /// @dev Allowance of user in ERC-20 representation
  mapping(address => mapping(address => uint256)) public allowance;

  /// @dev Approval in ERC-721 representaion
  mapping(uint256 => address) public getApproved;

  /// @dev Approval for all in ERC-721 representation
  mapping(address => mapping(address => bool)) public isApprovedForAll;

  /// @dev Packed representation of ownerOf and owned indices
  mapping(uint256 => uint256) internal _ownedData;

  /// @dev Array of owned ids in ERC-721 representation
  mapping(address => uint16[]) internal _owned;

  /// @dev Addresses that are exempt from ERC-721 transfer, typically for gas savings (pairs, routers, etc)
  mapping(address => bool) internal _erc721TransferExempt;

  /// @dev EIP-2612 nonces
  mapping(address => uint256) public nonces;

  /// @dev Address bitmask for packed ownership data
  uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

  /// @dev Owned index bitmask for packed ownership data
  uint256 private constant _BITMASK_OWNED_INDEX = ((1 << 96) - 1) << 160;

  /// @dev Constant for token id encoding
  uint256 public constant ID_ENCODING_PREFIX = 1 << 255;

  constructor(string memory name_, string memory symbol_, uint8 decimals_) {
    name = name_;
    symbol = symbol_;

    if (decimals_ < 18) {
      revert DecimalsTooLow();
    }

    decimals = decimals_;
    units = 10 ** decimals;

    // EIP-2612 initialization
    _INITIAL_CHAIN_ID = block.chainid;
    _INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
  }

  /// @notice Function to find owner of a given ERC-721 token
  function ownerOf(
    uint256 id_
  ) public view virtual returns (address erc721Owner) {
    erc721Owner = _getOwnerOf(id_);

    if (!_isValidTokenId(id_)) {
      revert InvalidTokenId();
    }

    if (erc721Owner == address(0)) {
      revert NotFound();
    }
  }

  function owned(
    address owner_
  ) public view virtual returns (uint256[] memory) {
    uint256[] memory ownedAsU256 = new uint256[](_owned[owner_].length);

    for (uint256 i = 0; i < _owned[owner_].length; ) {
      ownedAsU256[i] = ID_ENCODING_PREFIX + _owned[owner_][i];

      unchecked {
        ++i;
      }
    }

    return ownedAsU256;
  }

  function erc721BalanceOf(
    address owner_
  ) public view virtual returns (uint256) {
    return _owned[owner_].length;
  }

  function erc20BalanceOf(
    address owner_
  ) public view virtual returns (uint256) {
    return balanceOf[owner_];
  }

  function erc20TotalSupply() public view virtual returns (uint256) {
    return totalSupply;
  }

  function erc721TotalSupply() public view virtual returns (uint256) {
    return minted;
  }

  function getERC721QueueLength() public view virtual returns (uint256) {
    return _storedERC721Ids.length();
  }

  function getERC721TokensInQueue(
    uint256 start_,
    uint256 count_
  ) public view virtual returns (uint256[] memory) {
    uint256[] memory tokensInQueue = new uint256[](count_);

    for (uint256 i = start_; i < start_ + count_; ) {
      tokensInQueue[i - start_] = ID_ENCODING_PREFIX + _storedERC721Ids.at(i);

      unchecked {
        ++i;
      }
    }

    return tokensInQueue;
  }

  /// @notice tokenURI must be implemented by child contract
  function tokenURI(uint256 id_) public view virtual returns (string memory);

  /// @notice Function for token approvals
  /// @dev This function assumes the operator is attempting to approve an ERC-721
  ///      if valueOrId is less than the minted count. Unlike setApprovalForAll,
  ///      spender_ must be allowed to be 0x0 so that approval can be revoked.
  function approve(
    address spender_,
    uint256 valueOrId_
  ) public virtual returns (bool) {
    // The ERC-721 tokens are 1-indexed, so 0 is not a valid id and indicates that
    // operator is attempting to set the ERC-20 allowance to 0.
    if (_isValidTokenId(valueOrId_)) {
      erc721Approve(spender_, valueOrId_);
    } else {
      return erc20Approve(spender_, valueOrId_);
    }

    return true;
  }

  function erc721Approve(address spender_, uint256 id_) public virtual {
    // Intention is to approve as ERC-721 token (id).
    address erc721Owner = _getOwnerOf(id_);

    if (
      msg.sender != erc721Owner && !isApprovedForAll[erc721Owner][msg.sender]
    ) {
      revert Unauthorized();
    }

    getApproved[id_] = spender_;

    emit ERC721Events.Approval(erc721Owner, spender_, id_);
  }

  /// @dev Providing type(uint256).max for approval value results in an
  ///      unlimited approval that is not deducted from on transfers.
  function erc20Approve(
    address spender_,
    uint256 value_
  ) public virtual returns (bool) {
    // Prevent granting 0x0 an ERC-20 allowance.
    if (spender_ == address(0)) {
      revert InvalidSpender();
    }

    // Intention is to approve as ERC-20 token (value).
    allowance[msg.sender][spender_] = value_;

    emit ERC20Events.Approval(msg.sender, spender_, value_);

    return true;
  }

  /// @notice Function for ERC-721 approvals
  function setApprovalForAll(address operator_, bool approved_) public virtual {
    // Prevent approvals to 0x0.
    if (operator_ == address(0)) {
      revert InvalidOperator();
    }
    isApprovedForAll[msg.sender][operator_] = approved_;
    emit ERC721Events.ApprovalForAll(msg.sender, operator_, approved_);
  }

  /// @notice Function for mixed transfers from an operator that may be different than 'from'.
  /// @dev This function assumes the operator is attempting to transfer an ERC-721
  ///      if valueOrId is less than or equal to current max id.
  function transferFrom(
    address from_,
    address to_,
    uint256 valueOrId_
  ) public virtual returns (bool) {
    if (_isValidTokenId(valueOrId_)) {
      erc721TransferFrom(from_, to_, valueOrId_);
    } else {
      // Intention is to transfer as ERC-20 token (value).
      return erc20TransferFrom(from_, to_, valueOrId_);
    }

    return true;
  }

  /// @notice Function for ERC-721 transfers from.
  /// @dev This function is recommended for ERC721 transfers
  function erc721TransferFrom(
    address from_,
    address to_,
    uint256 id_
  ) public virtual {
    // Prevent transferring tokens from 0x0.
    if (from_ == address(0)) {
      revert InvalidSender();
    }

    // Prevent burning tokens to 0x0.
    if (to_ == address(0)) {
      revert InvalidRecipient();
    }

    if (from_ != _getOwnerOf(id_)) {
      revert Unauthorized();
    }

    // Check that the operator is either the sender or approved for the transfer.
    if (
      msg.sender != from_ &&
      !isApprovedForAll[from_][msg.sender] &&
      msg.sender != getApproved[id_]
    ) {
      revert Unauthorized();
    }

    if (erc721TransferExempt(to_)) {
      revert RecipientIsERC721TransferExempt();
    }

    // Transfer 1 * units ERC-20 and 1 ERC-721 token.
    // ERC-721 transfer exemptions handled above. Can't make it to this point if either is transfer exempt.
    _transferERC20(from_, to_, units);
    _transferERC721(from_, to_, id_);
  }

  /// @notice Function for ERC-20 transfers from.
  /// @dev This function is recommended for ERC20 transfers
  function erc20TransferFrom(
    address from_,
    address to_,
    uint256 value_
  ) public virtual returns (bool) {
    // Prevent transferring tokens from 0x0.
    if (from_ == address(0)) {
      revert InvalidSender();
    }

    // Prevent burning tokens to 0x0.
    if (to_ == address(0)) {
      revert InvalidRecipient();
    }

    // Intention is to transfer as ERC-20 token (value).
    uint256 allowed = allowance[from_][msg.sender];

    // Check that the operator has sufficient allowance.
    if (allowed != type(uint256).max) {
      allowance[from_][msg.sender] = allowed - value_;
    }

    // Transferring ERC-20s directly requires the _transfer function.
    // Handles ERC-721 exemptions internally.
    return _transferERC20WithERC721(from_, to_, value_);
  }

  /// @notice Function for ERC-20 transfers.
  /// @dev This function assumes the operator is attempting to transfer as ERC-20
  ///      given this function is only supported on the ERC-20 interface.
  ///      Treats even small amounts that are valid ERC-721 ids as ERC-20s.
  function transfer(address to_, uint256 value_) public virtual returns (bool) {
    // Prevent burning tokens to 0x0.
    if (to_ == address(0)) {
      revert InvalidRecipient();
    }

    // Transferring ERC-20s directly requires the _transfer function.
    // Handles ERC-721 exemptions internally.
    return _transferERC20WithERC721(msg.sender, to_, value_);
  }

  /// @notice Function for ERC-721 transfers with contract support.
  /// This function only supports moving valid ERC-721 ids, as it does not exist on the ERC-20
  /// spec and will revert otherwise.
  function safeTransferFrom(
    address from_,
    address to_,
    uint256 id_
  ) public virtual {
    safeTransferFrom(from_, to_, id_, "");
  }

  /// @notice Function for ERC-721 transfers with contract support and callback data.
  /// This function only supports moving valid ERC-721 ids, as it does not exist on the
  /// ERC-20 spec and will revert otherwise.
  function safeTransferFrom(
    address from_,
    address to_,
    uint256 id_,
    bytes memory data_
  ) public virtual {
    if (!_isValidTokenId(id_)) {
      revert InvalidTokenId();
    }

    transferFrom(from_, to_, id_);

    if (
      to_.code.length != 0 &&
      IERC721Receiver(to_).onERC721Received(msg.sender, from_, id_, data_) !=
      IERC721Receiver.onERC721Received.selector
    ) {
      revert UnsafeRecipient();
    }
  }

  /// @notice Function for EIP-2612 permits
  /// @dev Providing type(uint256).max for permit value results in an
  ///      unlimited approval that is not deducted from on transfers.
  function permit(
    address owner_,
    address spender_,
    uint256 value_,
    uint256 deadline_,
    uint8 v_,
    bytes32 r_,
    bytes32 s_
  ) public virtual {
    if (deadline_ < block.timestamp) {
      revert PermitDeadlineExpired();
    }

    if (_isValidTokenId(value_)) {
      revert InvalidApproval();
    }

    if (spender_ == address(0)) {
      revert InvalidSpender();
    }

    unchecked {
      address recoveredAddress = ecrecover(
        keccak256(
          abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR(),
            keccak256(
              abi.encode(
                keccak256(
                  "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                ),
                owner_,
                spender_,
                value_,
                nonces[owner_]++,
                deadline_
              )
            )
          )
        ),
        v_,
        r_,
        s_
      );

      if (recoveredAddress == address(0) || recoveredAddress != owner_) {
        revert InvalidSigner();
      }

      allowance[recoveredAddress][spender_] = value_;
    }

    emit ERC20Events.Approval(owner_, spender_, value_);
  }

  /// @notice Returns domain initial domain separator, or recomputes if chain id is not equal to initial chain id
  function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
    return
      block.chainid == _INITIAL_CHAIN_ID
        ? _INITIAL_DOMAIN_SEPARATOR
        : _computeDomainSeparator();
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual returns (bool) {
    return
      interfaceId == type(IERC404).interfaceId ||
      interfaceId == type(IERC165).interfaceId;
  }

  /// @notice Function for self-exemption
  function setSelfERC721TransferExempt(bool state_) public virtual {
    _setERC721TransferExempt(msg.sender, state_);
  }

  /// @notice Function to check if address is transfer exempt
  function erc721TransferExempt(
    address target_
  ) public view virtual returns (bool) {
    return target_ == address(0) || _erc721TransferExempt[target_];
  }

  /// @notice For a token token id to be considered valid, it just needs
  ///         to fall within the range of possible token ids, it does not
  ///         necessarily have to be minted yet.
  function _isValidTokenId(uint256 id_) internal pure returns (bool) {
    return id_ > ID_ENCODING_PREFIX && id_ != type(uint256).max;
  }

  /// @notice Internal function to compute domain separator for EIP-2612 permits
  function _computeDomainSeparator() internal view virtual returns (bytes32) {
    return
      keccak256(
        abi.encode(
          keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
          ),
          keccak256(bytes(name)),
          keccak256("1"),
          block.chainid,
          address(this)
        )
      );
  }

  /// @notice This is the lowest level ERC-20 transfer function, which
  ///         should be used for both normal ERC-20 transfers as well as minting.
  /// Note that this function allows transfers to and from 0x0.
  function _transferERC20(
    address from_,
    address to_,
    uint256 value_
  ) internal virtual {
    // Minting is a special case for which we should not check the balance of
    // the sender, and we should increase the total supply.
    if (from_ == address(0)) {
      totalSupply += value_;
    } else {
      // Deduct value from sender's balance.
      balanceOf[from_] -= value_;
    }

    // Update the recipient's balance.
    // Can be unchecked because on mint, adding to totalSupply is checked, and on transfer balance deduction is checked.
    unchecked {
      balanceOf[to_] += value_;
    }

    emit ERC20Events.Transfer(from_, to_, value_);
  }

  /// @notice Consolidated record keeping function for transferring ERC-721s.
  /// @dev Assign the token to the new owner, and remove from the old owner.
  /// Note that this function allows transfers to and from 0x0.
  /// Does not handle ERC-721 exemptions.
  function _transferERC721(
    address from_,
    address to_,
    uint256 id_
  ) internal virtual {
    // If this is not a mint, handle record keeping for transfer from previous owner.
    if (from_ != address(0)) {
      // On transfer of an NFT, any previous approval is reset.
      delete getApproved[id_];

      uint256 updatedId = ID_ENCODING_PREFIX +
        _owned[from_][_owned[from_].length - 1];
      if (updatedId != id_) {
        uint256 updatedIndex = _getOwnedIndex(id_);
        // update _owned for sender
        _owned[from_][updatedIndex] = uint16(updatedId);
        // update index for the moved id
        _setOwnedIndex(updatedId, updatedIndex);
      }

      // pop
      _owned[from_].pop();
    }

    // Check if this is a burn.
    if (to_ != address(0)) {
      // If not a burn, update the owner of the token to the new owner.
      // Update owner of the token to the new owner.
      _setOwnerOf(id_, to_);
      // Push token onto the new owner's stack.
      _owned[to_].push(uint16(id_));
      // Update index for new owner's stack.
      _setOwnedIndex(id_, _owned[to_].length - 1);
    } else {
      // If this is a burn, reset the owner of the token to 0x0 by deleting the token from _ownedData.
      delete _ownedData[id_];
    }

    emit ERC721Events.Transfer(from_, to_, id_);
  }

  /// @notice Internal function for ERC-20 transfers. Also handles any ERC-721 transfers that may be required.
  // Handles ERC-721 exemptions.
  function _transferERC20WithERC721(
    address from_,
    address to_,
    uint256 value_
  ) internal virtual returns (bool) {
    uint256 erc20BalanceOfSenderBefore = erc20BalanceOf(from_);
    uint256 erc20BalanceOfReceiverBefore = erc20BalanceOf(to_);

    _transferERC20(from_, to_, value_);

    // Preload for gas savings on branches
    bool isFromERC721TransferExempt = erc721TransferExempt(from_);
    bool isToERC721TransferExempt = erc721TransferExempt(to_);

    // Skip _withdrawAndStoreERC721 and/or _retrieveOrMintERC721 for ERC-721 transfer exempt addresses
    // 1) to save gas
    // 2) because ERC-721 transfer exempt addresses won't always have/need ERC-721s corresponding to their ERC20s.
    if (isFromERC721TransferExempt && isToERC721TransferExempt) {
      // Case 1) Both sender and recipient are ERC-721 transfer exempt. No ERC-721s need to be transferred.
      // NOOP.
    } else if (isFromERC721TransferExempt) {
      // Case 2) The sender is ERC-721 transfer exempt, but the recipient is not. Contract should not attempt
      //         to transfer ERC-721s from the sender, but the recipient should receive ERC-721s
      //         from the bank/minted for any whole number increase in their balance.
      // Only cares about whole number increments.
      uint256 tokensToRetrieveOrMint = (balanceOf[to_] / units) -
        (erc20BalanceOfReceiverBefore / units);
      for (uint256 i = 0; i < tokensToRetrieveOrMint; ) {
        _retrieveOrMintERC721(to_);
        unchecked {
          ++i;
        }
      }
    } else if (isToERC721TransferExempt) {
      // Case 3) The sender is not ERC-721 transfer exempt, but the recipient is. Contract should attempt
      //         to withdraw and store ERC-721s from the sender, but the recipient should not
      //         receive ERC-721s from the bank/minted.
      // Only cares about whole number increments.
      uint256 tokensToWithdrawAndStore = (erc20BalanceOfSenderBefore / units) -
        (balanceOf[from_] / units);
      for (uint256 i = 0; i < tokensToWithdrawAndStore; ) {
        _withdrawAndStoreERC721(from_);
        unchecked {
          ++i;
        }
      }
    } else {
      // Case 4) Neither the sender nor the recipient are ERC-721 transfer exempt.
      // Strategy:
      // 1. First deal with the whole tokens. These are easy and will just be transferred.
      // 2. Look at the fractional part of the value:
      //   a) If it causes the sender to lose a whole token that was represented by an NFT due to a
      //      fractional part being transferred, withdraw and store an additional NFT from the sender.
      //   b) If it causes the receiver to gain a whole new token that should be represented by an NFT
      //      due to receiving a fractional part that completes a whole token, retrieve or mint an NFT to the recevier.

      // Whole tokens worth of ERC-20s get transferred as ERC-721s without any burning/minting.
      uint256 nftsToTransfer = value_ / units;
      for (uint256 i = 0; i < nftsToTransfer; ) {
        // Pop from sender's ERC-721 stack and transfer them (LIFO)
        uint256 indexOfLastToken = _owned[from_].length - 1;
        uint256 tokenId = ID_ENCODING_PREFIX + _owned[from_][indexOfLastToken];
        _transferERC721(from_, to_, tokenId);
        unchecked {
          ++i;
        }
      }

      // If the sender's transaction changes their holding from a fractional to a non-fractional
      // amount (or vice versa), adjust ERC-721s.
      //
      // Check if the send causes the sender to lose a whole token that was represented by an ERC-721
      // due to a fractional part being transferred.
      if (
        erc20BalanceOfSenderBefore / units - erc20BalanceOf(from_) / units >
        nftsToTransfer
      ) {
        _withdrawAndStoreERC721(from_);
      }

      if (
        erc20BalanceOf(to_) / units - erc20BalanceOfReceiverBefore / units >
        nftsToTransfer
      ) {
        _retrieveOrMintERC721(to_);
      }
    }

    return true;
  }

  /// @notice Internal function for ERC20 minting
  /// @dev This function will allow minting of new ERC20s.
  ///      If mintCorrespondingERC721s_ is true, and the recipient is not ERC-721 exempt, it will
  ///      also mint the corresponding ERC721s.
  /// Handles ERC-721 exemptions.
  function _mintERC20(address to_, uint256 value_) internal virtual {
    /// You cannot mint to the zero address (you can't mint and immediately burn in the same transfer).
    if (to_ == address(0)) {
      revert InvalidRecipient();
    }

    if (totalSupply + value_ > ID_ENCODING_PREFIX) {
      revert MintLimitReached();
    }

    _transferERC20WithERC721(address(0), to_, value_);
  }

  /// @notice Internal function for ERC-721 minting and retrieval from the bank.
  /// @dev This function will allow minting of new ERC-721s up to the total fractional supply. It will
  ///      first try to pull from the bank, and if the bank is empty, it will mint a new token.
  /// Does not handle ERC-721 exemptions.
  function _retrieveOrMintERC721(address to_) internal virtual {
    if (to_ == address(0)) {
      revert InvalidRecipient();
    }

    uint256 id;

    if (!_storedERC721Ids.empty()) {
      // If there are any tokens in the bank, use those first.
      // Pop off the end of the queue (FIFO).
      id = ID_ENCODING_PREFIX + _storedERC721Ids.popBack();
    } else {
      // Otherwise, mint a new token, should not be able to go over the total fractional supply.
      ++minted;

      // Reserve max uint256 for approvals
      if (minted == type(uint256).max) {
        revert MintLimitReached();
      }

      id = ID_ENCODING_PREFIX + minted;
    }

    address erc721Owner = _getOwnerOf(id);

    // The token should not already belong to anyone besides 0x0 or this contract.
    // If it does, something is wrong, as this should never happen.
    if (erc721Owner != address(0)) {
      revert AlreadyExists();
    }

    // Transfer the token to the recipient, either transferring from the contract's bank or minting.
    // Does not handle ERC-721 exemptions.
    _transferERC721(erc721Owner, to_, id);
  }

  /// @notice Internal function for ERC-721 deposits to bank (this contract).
  /// @dev This function will allow depositing of ERC-721s to the bank, which can be retrieved by future minters.
  // Does not handle ERC-721 exemptions.
  function _withdrawAndStoreERC721(address from_) internal virtual {
    if (from_ == address(0)) {
      revert InvalidSender();
    }

    // Retrieve the latest token added to the owner's stack (LIFO).
    uint256 id = ID_ENCODING_PREFIX + _owned[from_][_owned[from_].length - 1];

    // Transfer to 0x0.
    // Does not handle ERC-721 exemptions.
    _transferERC721(from_, address(0), id);

    // Record the token in the contract's bank queue.
    _storedERC721Ids.pushFront(uint16(id));
  }

  /// @notice Initialization function to set pairs / etc, saving gas by avoiding mint / burn on unnecessary targets
  function _setERC721TransferExempt(
    address target_,
    bool state_
  ) internal virtual {
    if (target_ == address(0)) {
      revert InvalidExemption();
    }

    // Adjust the ERC721 balances of the target to respect exemption rules.
    // Despite this logic, it is still recommended practice to exempt prior to the target
    // having an active balance.
    if (state_) {
      _clearERC721Balance(target_);
    } else {
      _reinstateERC721Balance(target_);
    }

    _erc721TransferExempt[target_] = state_;
  }

  /// @notice Function to reinstate balance on exemption removal
  function _reinstateERC721Balance(address target_) private {
    uint256 expectedERC721Balance = erc20BalanceOf(target_) / units;
    uint256 actualERC721Balance = erc721BalanceOf(target_);

    for (uint256 i = 0; i < expectedERC721Balance - actualERC721Balance; ) {
      // Transfer ERC721 balance in from pool
      _retrieveOrMintERC721(target_);
      unchecked {
        ++i;
      }
    }
  }

  /// @notice Function to clear balance on exemption inclusion
  function _clearERC721Balance(address target_) private {
    uint256 erc721Balance = erc721BalanceOf(target_);

    for (uint256 i = 0; i < erc721Balance; ) {
      // Transfer out ERC721 balance
      _withdrawAndStoreERC721(target_);
      unchecked {
        ++i;
      }
    }
  }

  function _getOwnerOf(
    uint256 id_
  ) internal view virtual returns (address ownerOf_) {
    uint256 data = _ownedData[id_];

    assembly {
      ownerOf_ := and(data, _BITMASK_ADDRESS)
    }
  }

  function _setOwnerOf(uint256 id_, address owner_) internal virtual {
    uint256 data = _ownedData[id_];

    assembly {
      data := add(
        and(data, _BITMASK_OWNED_INDEX),
        and(owner_, _BITMASK_ADDRESS)
      )
    }

    _ownedData[id_] = data;
  }

  function _getOwnedIndex(
    uint256 id_
  ) internal view virtual returns (uint256 ownedIndex_) {
    uint256 data = _ownedData[id_];

    assembly {
      ownedIndex_ := shr(160, data)
    }
  }

  function _setOwnedIndex(uint256 id_, uint256 index_) internal virtual {
    uint256 data = _ownedData[id_];

    if (index_ > _BITMASK_OWNED_INDEX >> 160) {
      revert OwnedIndexOverflow();
    }

    assembly {
      data := add(
        and(data, _BITMASK_ADDRESS),
        and(shl(160, index_), _BITMASK_OWNED_INDEX)
      )
    }

    _ownedData[id_] = data;
  }
}

// File: @openzeppelin/contracts/utils/math/SignedMath.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;



/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/examples/ERC404ExampleU16.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;




contract ERC404ExampleU16 is Ownable, ERC404U16 {
  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    uint256 maxTotalSupplyERC721_,
    address initialOwner_,
    address initialMintRecipient_
  ) ERC404U16(name_, symbol_, decimals_) Ownable(initialOwner_) {
    // Do not mint the ERC721s to the initial owner, as it's a waste of gas.
    _setERC721TransferExempt(initialMintRecipient_, true);
    _mintERC20(initialMintRecipient_, maxTotalSupplyERC721_ * units);
  }

  function tokenURI(uint256 id_) public pure override returns (string memory) {
    return string.concat("https://example.com/token/", Strings.toString(id_));
  }

  function setERC721TransferExempt(
    address account_,
    bool value_
  ) external onlyOwner {
    _setERC721TransferExempt(account_, value_);
  }
}
