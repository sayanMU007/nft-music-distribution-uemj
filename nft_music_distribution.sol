// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract NFTMusicDistribution {
    struct MusicNFT {
        uint256 id;
        string title;
        string artist;
        uint256 price;
        string ipfsHash;
        address creator;
        uint256 royaltyPercentage;
        bool isForSale;
    }
    
    struct Artist {
        string name;
        string biography;
        bool isVerified;
        uint256 totalSales;
        uint256 royaltiesEarned;
    }
    
    // Project details
    string public projectTitle;
    string public projectDescription;
    string public projectVision;
    string public futureScope;
    string public keyFeatures;
    
    // Contract variables
    address public owner;
    uint256 public platformFeePercentage;
    uint256 private nftCounter;
    
    // Mappings
    mapping(uint256 => MusicNFT) public musicNFTs;
    mapping(address => Artist) public artists;
    mapping(address => uint256[]) public artistNFTs;
    mapping(address => uint256) public artistBalance;
    mapping(address => bool) public isArtist;
    
    // Events
    event NFTMinted(uint256 indexed id, address indexed creator, string title, uint256 price);
    event NFTSold(uint256 indexed id, address indexed seller, address indexed buyer, uint256 price);
    event RoyaltyPaid(uint256 indexed id, address indexed creator, uint256 amount);
    event ArtistRegistered(address indexed artistAddress, string name);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    
    constructor() {
        owner = msg.sender;
        platformFeePercentage = 250; // 2.5% platform fee (in basis points)
        nftCounter = 0;
        
        projectTitle = "NFT MUSIC DISTRIBUTION";
        projectDescription = "Allow musicians to sell their music as NFTs, giving them direct royalties.";
        projectVision = "Empowering musicians by decentralizing music ownership and revenue streams.";
        futureScope = "Expansion into metaverse concerts, AI-powered music curation, and fan-engagement features.";
        keyFeatures = "NFT minting, royalty tracking, decentralized storage, and marketplace integration.";
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }
    
    modifier onlyArtist() {
        require(isArtist[msg.sender], "Only registered artists can perform this action");
        _;
    }
    
    function getProjectDetails() public view returns (
        string memory, string memory, string memory, string memory, string memory
    ) {
        return (projectTitle, projectDescription, projectVision, futureScope, keyFeatures);
    }
    
    function updateProjectDetails(
        string memory _title, 
        string memory _description,
        string memory _vision,
        string memory _futureScope,
        string memory _keyFeatures
    ) public onlyOwner {
        projectTitle = _title;
        projectDescription = _description;
        projectVision = _vision;
        futureScope = _futureScope;
        keyFeatures = _keyFeatures;
    }
    
    function registerArtist(string memory _name, string memory _biography) public {
        require(!isArtist[msg.sender], "Artist already registered");
        
        Artist memory newArtist = Artist({
            name: _name,
            biography: _biography,
            isVerified: false,
            totalSales: 0,
            royaltiesEarned: 0
        });
        
        artists[msg.sender] = newArtist;
        isArtist[msg.sender] = true;
        
        emit ArtistRegistered(msg.sender, _name);
    }
    
    function verifyArtist(address _artistAddress) public onlyOwner {
        require(isArtist[_artistAddress], "Address is not registered as an artist");
        artists[_artistAddress].isVerified = true;
    }
    
    function mintNFT(
        string memory _title,
        string memory _ipfsHash,
        uint256 _price,
        uint256 _royaltyPercentage
    ) public onlyArtist returns (uint256) {
        require(_royaltyPercentage <= 5000, "Royalty percentage cannot exceed 50%");
        
        nftCounter++;
        uint256 newNftId = nftCounter;
        
        MusicNFT memory newNFT = MusicNFT({
            id: newNftId,
            title: _title,
            artist: artists[msg.sender].name,
            price: _price,
            ipfsHash: _ipfsHash,
            creator: msg.sender,
            royaltyPercentage: _royaltyPercentage,
            isForSale: true
        });
        
        musicNFTs[newNftId] = newNFT;
        artistNFTs[msg.sender].push(newNftId);
        
        emit NFTMinted(newNftId, msg.sender, _title, _price);
        
        return newNftId;
    }
    
    function buyNFT(uint256 _nftId) public payable {
        MusicNFT storage nft = musicNFTs[_nftId];
        
        require(nft.id > 0, "NFT does not exist");
        require(nft.isForSale, "NFT is not for sale");
        require(msg.value >= nft.price, "Insufficient payment");
        
        address seller = nft.creator;
        uint256 price = nft.price;
        
        // Calculate platform fee
        uint256 platformFee = (price * platformFeePercentage) / 10000;
        uint256 sellerAmount = price - platformFee;
        
        // Update NFT ownership
        nft.creator = msg.sender;
        nft.isForSale = false;
        
        // Update artist stats
        artists[seller].totalSales += price;
        
        // Add to seller's balance
        artistBalance[seller] += sellerAmount;
        
        // Add NFT to buyer's collection
        artistNFTs[msg.sender].push(_nftId);
        
        // Remove from seller's collection (optional implementation)
        
        emit NFTSold(_nftId, seller, msg.sender, price);
    }
    
    function resellNFT(uint256 _nftId, uint256 _newPrice) public {
        MusicNFT storage nft = musicNFTs[_nftId];
        
        require(nft.id > 0, "NFT does not exist");
        require(nft.creator == msg.sender, "You don't own this NFT");
        
        nft.price = _newPrice;
        nft.isForSale = true;
    }
    
    function withdrawFunds() public {
        uint256 amount = artistBalance[msg.sender];
        require(amount > 0, "No funds to withdraw");
        
        artistBalance[msg.sender] = 0;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(msg.sender, amount);
    }
    
    function getArtistNFTs(address _artist) public view returns (uint256[] memory) {
        return artistNFTs[_artist];
    }
    
    function getNFTDetails(uint256 _nftId) public view returns (
        uint256, string memory, string memory, uint256, string memory, address, uint256, bool
    ) {
        MusicNFT memory nft = musicNFTs[_nftId];
        require(nft.id > 0, "NFT does not exist");
        
        return (
            nft.id,
            nft.title,
            nft.artist,
            nft.price,
            nft.ipfsHash,
            nft.creator,
            nft.royaltyPercentage,
            nft.isForSale
        );
    }
    
    function updatePlatformFee(uint256 _newFeePercentage) public onlyOwner {
        require(_newFeePercentage <= 1000, "Platform fee cannot exceed 10%");
        platformFeePercentage = _newFeePercentage;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }
}
