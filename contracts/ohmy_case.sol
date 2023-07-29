// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OhmyCase is ERC721Enumerable, ERC721URIStorage, AccessControl, Ownable {
    struct NFTCase {
        uint8 caseType;
        uint256 currentMiles;
        uint256 milesCapacity;
        uint256 ohmyStartPrice;
    }

    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => string) private _tokenImageURIs; // Mapping to store IPFS image URLs
    NFTCase[] private _nftCases;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Caller is not a manager");
        _;
    }

    constructor() ERC721("NFT Storage", "NFTS") {}

    function initialize() public initializer {
        __ERC721_init("NFT Storage", "NFTS");
        __ERC721URIStorage_init();
        __AccessControl_init();
        __Ownable_init();

        _setupRole(OWNER_ROLE, _msgSender());
        _setRoleAdmin(MANAGER_ROLE, OWNER_ROLE);
    }

    function createNFTCase(
        uint8 caseType,
        uint256 milesCapacity,
        uint256 ohmyStartPrice,
        string memory tokenURI,
        string memory imageURI // IPFS image URL as a parameter
    ) external onlyManager {
        require(caseType < 3, "Invalid case type");
        require(milesCapacity > 0, "Miles capacity must be greater than 0");
        require(ohmyStartPrice > 0, "OHMY price must be greater than 0");

        uint256 tokenId = _nftCases.length;
        _mint(_msgSender(), tokenId);
        _setTokenURI(tokenId, tokenURI);

        _nftCases.push(NFTCase({
            caseType: caseType,
            currentMiles: 0,
            milesCapacity: milesCapacity,
            ohmyStartPrice: ohmyStartPrice
        }));

        // Store IPFS image URL in the mapping
        _tokenImageURIs[tokenId] = imageURI;
    }

    function updateMiles(uint256 tokenId, uint256 newMiles) external onlyManager {
        require(tokenId < _nftCases.length, "Invalid token ID");
        require(newMiles <= _nftCases[tokenId].milesCapacity, "Miles exceed capacity");

        _nftCases[tokenId].currentMiles = newMiles;
    }

    function updateMilesCapacity(uint256 tokenId, uint256 newCapacity) external onlyManager {
        require(tokenId < _nftCases.length, "Invalid token ID");
        require(newCapacity >= _nftCases[tokenId].currentMiles, "Capacity must be greater than current miles");

        _nftCases[tokenId].milesCapacity = newCapacity;
    }

    function getNFTCase(uint256 tokenId) external view returns (
        uint8 caseType,
        uint256 currentMiles,
        uint256 milesCapacity,
        uint256 ohmyStartPrice,
        string memory tokenURI,
        string memory imageURI // Return IPFS image URL
    ) {
        require(tokenId < _nftCases.length, "Invalid token ID");

        NFTCase storage nftCase = _nftCases[tokenId];
        return (
            nftCase.caseType,
            nftCase.currentMiles,
            nftCase.milesCapacity,
            nftCase.ohmyStartPrice,
            tokenURI(tokenId),
            _tokenImageURIs[tokenId] // Return IPFS image URL from the mapping
        );
    }
}