// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "hardhat/console.sol";

contract DarkRallyNFT is Initializable, ERC1155Upgradeable, AccessControlUpgradeable, 
         PausableUpgradeable, ERC1155BurnableUpgradeable, ERC1155SupplyUpgradeable, UUPSUpgradeable {
    // bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Struct Nft Info 
    struct NftInfo {                
        string nameOfNFT;  //ie: NFToy serie AA23-A   --only for show in getter function
        string category; //ie: Toys, Tickets, Tropheus, Vehicles, Skins --only for show in getter function
        string metadataHashIpfs;  //ie: QmNoLB8krmgfntxAHgaJrTE2Mf6NCPQ7ct1UvhH2pNkLeg        
        uint256 maxSupply; //ie: 3000          
        uint256 initialPrice; //ie 9  (it's supposed it's in US$)
        bool askDateForMint; // If true, the expiration date will be validated before minting.
        uint256 validUntil; // initially used for Tickets - expressed in epoch time        
        uint256 entriesCounter; //initially used for Tickets - could be updated
        bool tokenIsRegistered; //needed to determine if this token has been registered or not. It's a requirement to MINT
    }
    
    mapping(uint256 tokenId => NftInfo) public nftInfo;
    

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC1155_init("");
        __AccessControl_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }


    function registerNewTypeOfNft (
        uint256 tokenId, string memory nameOfNFT, string memory category,  string calldata metadataHashIpfs, 
        uint256 maxSupply, uint256 initialPrice, bool askDateForMint,  uint256 validUntil, uint256 entriesCounter
    ) public  onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
                
        require(!nftInfo[tokenId].tokenIsRegistered, "TokenId was already registered");
        require ( bytes(metadataHashIpfs).length > 32, "Check the MetadataHashIPFS entry");
        require (maxSupply > 0,"Maxsupply must be greater than 0");
        if (askDateForMint) require ( validUntil > block.timestamp, "Expiration date must be greater than current date");

        nftInfo[tokenId] = NftInfo(nameOfNFT, category, metadataHashIpfs, 
         maxSupply, initialPrice, askDateForMint, validUntil,  entriesCounter, true);  //true means tokenIsRegistered
    }


    function mint(address account, uint256 tokenId, uint256 amount)
        public
        onlyRole(MINTER_ROLE)
        whenNotPaused
    {        
        require(nftInfo[tokenId].tokenIsRegistered, "Token needs to be registered before mint");
        require(totalSupply(tokenId) + amount <= nftInfo[tokenId].maxSupply, "Limit of Supply for this token has been reached");        
        if (nftInfo[tokenId].askDateForMint) require ( nftInfo[tokenId].validUntil > block.timestamp, "This token has already expired");

        _mint(account, tokenId, amount, "");

    }
   
    function uri(uint256 _tokenId) public override view returns(string memory) {
        return (
            string(
                abi.encodePacked("https://ipfs.io/ipfs/", nftInfo[_tokenId].metadataHashIpfs)
            )
        );
    }


    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }


    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}