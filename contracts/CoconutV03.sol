// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {ERC721Utils} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Utils.sol";

/// @title Coconut
/// @author Merrill B. Lamont III (rockopera.eth)
/// @notice Own a design. Name that design. Make art onchain.
/// @dev Onchain art tech for onchain art work: 1 NFT design swatch for each of the 65K+ 4x4 design combinations.
contract CoconutV03 is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    /// @dev Custom string per unique tokenId, which can appear in the NFT pic.
    mapping(uint => string) private _tokenNames;

    // For converting from the decimal to the "xo" code.
    bytes2 private constant _XO_CODE = "ox";

    // Max value for tokenId.
    uint private constant _MAXTOKENID = 65535;

    // Base price per token.
    uint private constant _MINTPRICE = 0.001 ether;

    string private constant _SVG_PART_1 =
        '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="50%" y="16" text-anchor="middle" rotate="180" style="fill: black; font-size: 35px;">&#9814;</text><text x="50%" y="320" text-anchor="middle" class="base">';
    string private constant _SVG_PART_2 =
        '</text><text x="50%" y="337" text-anchor="middle" class="base">#';
    string private constant _SVG_PART_3 =
        '</text><rect x="50" y="50" width="250" height="250" fill="#808080"/>';
    string private constant _SVG_SQUARE_01 =
        '<rect x="55" y="55" width="60" height="60" fill="#';
    string private constant _SVG_SQUARE_02 =
        '<rect x="115" y="55" width="60" height="60" fill="#';
    string private constant _SVG_SQUARE_03 =
        '<rect x="175" y="55" width="60" height="60" fill="#';
    string private constant _SVG_SQUARE_04 =
        '<rect x="235" y="55" width="60" height="60" fill="#';
    string private constant _SVG_SQUARE_05 =
        '<rect x="55" y="115" width="60" height="60" fill="#';
    string private constant _SVG_SQUARE_06 =
        '<rect x="115" y="115" width="60" height="60" fill="#';
    string private constant _SVG_SQUARE_07 =
        '<rect x="175" y="115" width="60" height="60" fill="#';
    string private constant _SVG_SQUARE_08 =
        '<rect x="235" y="115" width="60" height="60" fill="#';
    string private constant _SVG_SQUARE_09 =
        '<rect x="55" y="175" width="60" height="60" fill="#';
    string private constant _SVG_SQUARE_10 =
        '<rect x="115" y="175" width="60" height="60" fill="#';
    string private constant _SVG_SQUARE_11 =
        '<rect x="175" y="175" width="60" height="60" fill="#';
    string private constant _SVG_SQUARE_12 =
        '<rect x="235" y="175" width="60" height="60" fill="#';
    string private constant _SVG_SQUARE_13 =
        '<rect x="55" y="235" width="60" height="60" fill="#';
    string private constant _SVG_SQUARE_14 =
        '<rect x="115" y="235" width="60" height="60" fill="#';
    string private constant _SVG_SQUARE_15 =
        '<rect x="175" y="235" width="60" height="60" fill="#';
    string private constant _SVG_SQUARE_16 =
        '<rect x="235" y="235" width="60" height="60" fill="#';
    string private constant _SVG_SQUARE_END_CAP = '"/>';
    string private constant _SVG_CODE_END_CAP = '"/></svg>';

    /// @notice Logs the change to the custom string per unique tokenId.
    event TokenRename(
        string indexed oldTokenName,
        string indexed newTokenName,
        uint indexed tokenId
    );

    /// @notice Logs who enacted the no-return ending of upgradeability.
    event UpgradeabilityEnded(address upgradeabilityEnder);

    /// @notice Logs the amount withdrawn.
    event Withdrew(uint amount);

    /// @notice Logs a deposit's sender and amount.
    event LogDepositReceived(address sender, uint amount);

    error InvalidTokenName();

    error NotTokenOwner();

    error ProxyContractCannotBeTokenOwner();

    error NothingToWithdraw();

    error WithdrawalFailed();

    error NeedMoreFundsForThisToken(uint mintPrice);

    error InvalidDesignxo();

    error InvalidTokenId();

    /// @notice Disallows this contract having its constructor meaningfully called upon proxy deployment/upgrade.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract.
    /// @param initialOwner The initial owner of the contract.
    /// @dev Called by deployment script, setting proxy-level attributes.
    function initialize(address initialOwner) public initializer {
        __ERC721_init("Rockopera Design", "ROD");
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    /// @notice Ends the upgradeability of the contract, non-reversably.
    /// @dev Only the contract owner can do this.
    function endUpgradeability() external onlyOwner {
        StorageSlot
            .getBooleanSlot(
                bytes32(
                    uint256(keccak256("eip1967.proxy.upgradeabilityEnded")) - 1
                )
            )
            .value = true;

        emit UpgradeabilityEnded(msg.sender);
    }

    /// @notice Has upgradeability ended?
    /// @return True for ended upgradeability, False for not ended.
    function upgradeabilityEnded() public view returns (bool) {
        return
            StorageSlot
                .getBooleanSlot(
                    bytes32(
                        uint256(
                            keccak256("eip1967.proxy.upgradeabilityEnded")
                        ) - 1
                    )
                )
                .value;
    }

    // Allows upgrade only if called by contract owner, and upgradeability has not ended.
    function _authorizeUpgrade(address) internal view override onlyOwner {
        require(!upgradeabilityEnded(), "Contract is not upgradeable");
    }

    // TODO: test the design tiers
    /// @notice Creates a token.
    /// @dev Validates designxo, then passes to a private function to actually do it.
    /// @param designxo Design's 16-digit "xo" representation.
    /// @param tokenName Design's name.
    function setToken(
        string calldata designxo,
        string calldata tokenName
    ) external payable {
        if (bytes(tokenName).length > 32) revert InvalidTokenName(); // cheapest check, first
        uint tokenId = aGetId(designxo); // gets tokenId
        if (tokenId == 0 || tokenId == _MAXTOKENID) {
            // extra premium pricing for: all-o, all-x
            if (msg.value < (10000 * _MINTPRICE))
                revert NeedMoreFundsForThisToken(10000 * _MINTPRICE);
        } else {
            // regular pricing for: the rest of the Rockopera Designs
            if (msg.value < _MINTPRICE)
                revert NeedMoreFundsForThisToken(_MINTPRICE);
        }
        _setToken(tokenId, tokenName);
    }

    function _setToken(uint tokenId, string calldata tokenName) internal {
        _mint(msg.sender, tokenId); // creates token (first ensures token doesn't exist)
        _tokenNames[tokenId] = tokenName; // rename token (first ensures token is owned, which also ensures that it exists)
        emit TokenRename("", tokenName, tokenId);
        ERC721Utils.checkOnERC721Received(
            _msgSender(),
            address(0),
            msg.sender,
            tokenId,
            ""
        ); // ensures that, if token recipient is a contract, then it can handle receiving tokens
    }

    /// @notice Removes all stored funds from the contract
    /// @dev Only the contract owner can do this.
    function withdraw() external onlyOwner {
        // gotta ensure the checks-effects-interactions pattern is always in here
        uint balanceOfThisContract = address(this).balance;
        if (balanceOfThisContract == 0) revert NothingToWithdraw();
        (bool success, ) = owner().call{value: balanceOfThisContract}(""); // call() doesn't require owner() wrapped in payable()
        if (!success) revert WithdrawalFailed();
        // OLD: payable(owner()).transfer(balanceOfThisContract);
        emit Withdrew(balanceOfThisContract);
    }

    /// @notice Receive function to just receive sent funds, and emits an event.
    receive() external payable {
        emit LogDepositReceived(msg.sender, msg.value);
    }

    /// @notice Fallback function just receives any sent funds, and emits an event.
    fallback() external payable {
        emit LogDepositReceived(msg.sender, msg.value);
    }

    /// @notice Destroys a token.
    /// @dev Validates designxo, then passes to a private function to actually do it.
    /// @param designxo Design's 16-digit "xo" representation.
    function nixToken(string calldata designxo) external {
        uint tokenId = aGetId(designxo); // gets tokenId
        _nixToken(tokenId);
    }

    function _nixToken(uint tokenId) internal onlyTokenOwner(tokenId) {
        _modTokenName(tokenId, ""); // de-names token
        _burn(tokenId); // destroys token (burn function doesn't check for owner-approval, so modifier does, also ensuring existence)
    }

    /// @notice Retrieves a token's owner.
    /// @dev Validates designxo, then passes to a private function to actually do it.
    /// @param designxo Design's 16-digit "xo" representation.
    /// @return tokenOwner Owner of token.
    function getTokenOwner(
        string calldata designxo
    ) external view returns (address tokenOwner) {
        uint tokenId = aGetId(designxo); // gets tokenId
        tokenOwner = _getTokenOwner(tokenId);
    }

    function _getTokenOwner(
        uint tokenId
    ) internal view returns (address tokenOwner) {
        tokenOwner = ownerOf(tokenId); // gets token's owner (first ensures token exists)
    }

    /// @notice Changes a token's owner.
    /// @dev Validates designxo, then passes to a private function to actually do it.
    /// @param designxo Design's 16-digit "xo" representation.
    /// @param newTokenOwner New owner of token.
    function modTokenOwner(
        string calldata designxo,
        address newTokenOwner
    ) external {
        uint tokenId = aGetId(designxo); // gets tokenId
        if (newTokenOwner == address(this))
            revert ProxyContractCannotBeTokenOwner();
        _modTokenOwner(tokenId, newTokenOwner);
    }

    function _modTokenOwner(uint tokenId, address newTokenOwner) internal {
        _safeTransfer(msg.sender, newTokenOwner, tokenId); // gives token (first ensures token exists and is owned)
    }

    /// @notice Retrieves a design's name.
    /// @dev Validates designxo, then passes to a private function to actually do it.
    /// @param designxo Design's 16-digit "xo" representation.
    /// @return tokenName Name of design.
    function getTokenName(
        string calldata designxo
    ) external view returns (string memory tokenName) {
        uint tokenId = aGetId(designxo); // gets tokenId
        if (_ownerOf(tokenId) == address(0)) revert InvalidTokenId(); // DNE
        tokenName = _getTokenName(tokenId);
    }

    function _getTokenName(
        uint tokenId
    ) internal view returns (string memory tokenName) {
        tokenName = _tokenNames[tokenId]; // gets token's name
    }

    /// @notice Changes a design's name.
    /// @dev Validates designxo, then passes to a private function to actually do it.
    /// @param designxo Design's 16-digit "xo" representation.
    /// @param newTokenName New name of design.
    function modTokenName(
        string calldata designxo,
        string calldata newTokenName
    ) external {
        uint tokenId = aGetId(designxo); // gets tokenId
        if (bytes(newTokenName).length > 32) revert InvalidTokenName();
        _modTokenName(tokenId, newTokenName);
    }

    function _modTokenName(
        uint tokenId,
        string memory newTokenName
    ) internal onlyTokenOwner(tokenId) {
        string memory oldTokenName = _getTokenName(tokenId);
        _tokenNames[tokenId] = newTokenName; // rename token (first ensures token is owned, which also ensures that it exists)
        emit TokenRename(oldTokenName, newTokenName, tokenId);
    }

    modifier onlyTokenOwner(uint tokenId) {
        if (_getTokenOwner(tokenId) != msg.sender) revert NotTokenOwner();
        _;
    }

    /// @notice Converts a design's designxo into its tokenId: the token's internal ID.
    /// @dev Validates and converts a design "xo" string into a decimal integer: the tokenId.
    /// @param designxo Design's 16-digit "xo" representation.
    /// @return n tokenId of design.
    function aGetId(string calldata designxo) public pure returns (uint n) {
        // decimal number 'n' is birthed, to be constructed, then returned
        bytes calldata designxoBytes = bytes(designxo); // so not repeatedly converting in for loop
        if (designxoBytes.length != 16) revert InvalidDesignxo();
        // design-xo code is iterated through, but starting with lowest numeral
        for (uint i; i < 16; ) {
            // "xo" code is represented as its place (0-127) within the ASCII character mapping
            uint a = uint8(designxoBytes[i]);
            // x:120, o:111
            unchecked {
                if (a != 111 && a != 120) revert InvalidDesignxo();
                n += uint(a == 120 ? 1 : 0) << i;
                ++i;
            }
        }
        if (n > _MAXTOKENID) revert InvalidTokenId();
    }

    /// @notice Converts a token's tokenId into its designxo: the design's 16-digit "xo" code.
    /// @dev Validates and converts a tokenId decimal integer into a "xo" string: the designxo.
    /// @param n Color's tokenId.
    /// @return designxo 16-digit "xo" representation of design.
    function getDesignxo(uint n) public pure returns (string memory designxo) {
        if (n > _MAXTOKENID) revert InvalidTokenId();
        bytes memory designxoBytes = new bytes(16); // design-xo code is one size
        for (uint i; i < 16; ) {
            // design-xo code is constructed, but starting with lowest numeral
            designxoBytes[i] = _XO_CODE[n & 0x1]; // convert the decimal number's 1 rightmost bit into a "xo" representation using bitwise AND
            n >>= 1; // shift the decimal number rightwards by 1 bit, allowing subsequent conversions of decimal number's 1 rightmost bit to a "xo" representation
            unchecked {
                ++i;
            }
        }
        if (designxoBytes.length != 16) revert InvalidDesignxo();
        designxo = string(designxoBytes); // color-hexadecimal number is actually a string, which is a stringing together of the correctly placed hexadecimal numerals
    }

    // TODO: set SVG-picture
    /// @notice Retrieves a token's URI.
    /// @dev Makes the JSON, which contains the name, description, and picture (an SVG), all on-chain.
    /// @param tokenId Design's tokenId.
    /// @return tokenUri Metadata, which includes a SVG-coded picture, of token.
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory tokenUri) {
        if (tokenId > _MAXTOKENID) revert InvalidTokenId();

        string memory tokenName = _getTokenName(tokenId);
        string memory designxo = getDesignxo(tokenId);

        // Pack SVG parts directly into bytes
        bytes memory svgBytes = abi.encodePacked(
            _SVG_PART_1,
            tokenName,
            _SVG_PART_2,
            designxo,
            _SVG_PART_3,
            designxo,
            _SVG_PART_4
        );

        // Base64 encode the SVG bytes
        string memory encodedSvg = Base64.encode(svgBytes);

        // Create and encode the JSON directly
        bytes memory jsonBytes = abi.encodePacked(
            '{"name": "',
            tokenName,
            '", "description": "a rockopera color for onchain art", "image": ',
            '"data:image/svg+xml;base64,',
            encodedSvg,
            '"}'
        );

        // Base64 encode the JSON and create the final URI
        tokenUri = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(jsonBytes)
            )
        );
    }
}
