// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import './ERC721A.sol';

contract GomzClubCollection is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    enum SalePhase {
        Closed,
        Whitelist,
        Public
    }

    uint256 public constant MAX_SUPPLY = 2022;
    uint256 public constant WHITELIST_SUPPLY_CAP = 1200;
    uint256 public constant OWNER_RESERVE_CAP = 600;
    uint256 public constant MAX_PER_WALLET = 5;
    uint256 public constant MAX_PER_TX = 3;

    uint256 public publicMintPrice = 0.0002 ether;
    uint256 public whitelistMintPrice = 0.0001 ether;
    uint256 public ownerReserveMinted;

    SalePhase public salePhase = SalePhase.Closed;

    mapping(address => bool) public whitelist;

    string private _baseTokenURI;
    string public placeholderURI;
    string public baseExtension = '.json';
    bool public revealed;

    event SalePhaseUpdated(SalePhase newPhase);
    event PricesUpdated(uint256 whitelistPrice, uint256 publicPrice);
    event BaseURIUpdated(string newBaseURI);
    event PlaceholderURIUpdated(string newPlaceholderURI);
    event BaseExtensionUpdated(string newBaseExtension);
    event RevealStateUpdated(bool revealed);
    event WhitelistUpdated(address indexed account, bool isWhitelisted);
    event Withdrawal(address indexed recipient, uint256 amount);

    constructor(string memory initialPlaceholderURI) ERC721A('GOMZ Club', 'GOMZ') {
        placeholderURI = initialPlaceholderURI;
    }

    function mintWhitelist(uint256 quantity) external payable nonReentrant {
        require(salePhase == SalePhase.Whitelist, 'Whitelist sale is not active');
        require(whitelist[msg.sender], 'Address is not whitelisted');
        require(totalSupply() + quantity <= WHITELIST_SUPPLY_CAP, 'Whitelist supply exhausted');

        _validateMint(msg.sender, quantity);
        require(msg.value == whitelistMintPrice * quantity, 'Incorrect ETH amount');

        _safeMint(msg.sender, quantity);
    }

    function mintPublic(uint256 quantity) external payable nonReentrant {
        require(salePhase == SalePhase.Public, 'Public sale is not active');

        _validateMint(msg.sender, quantity);
        require(msg.value == publicMintPrice * quantity, 'Incorrect ETH amount');

        _safeMint(msg.sender, quantity);
    }

    function ownerMint(address to, uint256 quantity) external onlyOwner {
        require(to != address(0), 'Invalid recipient');
        require(quantity > 0, 'Quantity must be greater than zero');
        require(ownerReserveMinted + quantity <= OWNER_RESERVE_CAP, 'Owner reserve exceeded');
        require(totalSupply() + quantity <= MAX_SUPPLY, 'Max supply exceeded');

        ownerReserveMinted += quantity;
        _safeMint(to, quantity);
    }

    function setSalePhase(SalePhase newPhase) external onlyOwner {
        salePhase = newPhase;
        emit SalePhaseUpdated(newPhase);
    }

    function setMintPrices(uint256 newWhitelistPrice, uint256 newPublicPrice) external onlyOwner {
        whitelistMintPrice = newWhitelistPrice;
        publicMintPrice = newPublicPrice;
        emit PricesUpdated(newWhitelistPrice, newPublicPrice);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    function setPlaceholderURI(string calldata newPlaceholderURI) external onlyOwner {
        placeholderURI = newPlaceholderURI;
        emit PlaceholderURIUpdated(newPlaceholderURI);
    }

    function setBaseExtension(string calldata newBaseExtension) external onlyOwner {
        baseExtension = newBaseExtension;
        emit BaseExtensionUpdated(newBaseExtension);
    }

    function setRevealState(bool isRevealed) external onlyOwner {
        revealed = isRevealed;
        emit RevealStateUpdated(isRevealed);
    }

    function seedWhitelist(address[] calldata accounts, bool isWhitelisted) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = isWhitelisted;
            emit WhitelistUpdated(accounts[i], isWhitelisted);
        }
    }

    function withdraw(address payable recipient) external onlyOwner {
        require(recipient != address(0), 'Invalid recipient');

        uint256 balance = address(this).balance;
        require(balance > 0, 'No ETH to withdraw');

        (bool success, ) = recipient.call{value: balance}('');
        require(success, 'Withdraw failed');

        emit Withdrawal(recipient, balance);
    }

    function remainingWhitelistSupply() external view returns (uint256) {
        if (totalSupply() >= WHITELIST_SUPPLY_CAP) {
            return 0;
        }

        return WHITELIST_SUPPLY_CAP - totalSupply();
    }

    function remainingOwnerReserve() external view returns (uint256) {
        return OWNER_RESERVE_CAP - ownerReserveMinted;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (!revealed) {
            return placeholderURI;
        }

        string memory baseURI = _baseURI();
        if (bytes(baseURI).length == 0) {
            return '';
        }

        return string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension));
    }

    function _startTokenId() internal pure virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _validateMint(address account, uint256 quantity) private view {
        require(quantity > 0, 'Quantity must be greater than zero');
        require(quantity <= MAX_PER_TX, 'Max per transaction exceeded');
        require(_numberMinted(account) + quantity <= MAX_PER_WALLET, 'Max per wallet exceeded');
        require(totalSupply() + quantity <= MAX_SUPPLY, 'Max supply exceeded');
    }
}
