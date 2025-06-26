// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";


contract HotelBookingNFT is ERC721, Ownable {
    struct DateRange {
        uint256 fromDate;
        uint256 toDate;
        uint256 roomNumber;
    }

    uint256 public nextTokenId = 1;
    mapping(uint256 => DateRange) public tokenToDateRange;  // tokenId -> DateRange
    mapping(uint256 => uint256[]) public roomToDates;  // roomNumber -> sorted fromDates
    mapping(uint256 => string) public tokenMetadataURIs;  // tokenId -> metadata URI

    constructor() ERC721("HotelBookingNFT", "HBNFT") {}

    // Mint a new NFT for a given date range and room number, with metadata URI
    function mintNFT(
        address to,
        uint256 fromDate,
        uint256 toDate,
        uint256 roomNumber,
        string memory metadataURI
    ) public onlyOwner returns (uint256) {
        require(fromDate < toDate, "Invalid date range");
        require(!isOverlapping(roomNumber, fromDate, toDate), "Overlapping booking");

        uint256 tokenId = nextTokenId++;
        _mint(to, tokenId);

        tokenToDateRange[tokenId] = DateRange(fromDate, toDate, roomNumber);
        addSortedDate(roomNumber, fromDate);
        tokenMetadataURIs[tokenId] = metadataURI;
        return tokenId;
    }


    // Ensure roomToDates[roomNumber] array is sorted by `fromDate`
    function addSortedDate(uint256 roomNumber, uint256 fromDate) internal {
        uint256[] storage dates = roomToDates[roomNumber];
        uint256 i = dates.length;
        dates.push(fromDate);

        while (i > 0 && dates[i - 1] > fromDate) {
            dates[i] = dates[i - 1];
            i--;
        }
        dates[i] = fromDate;
    }


    function isOverlapping(
        uint256 roomNumber,
        uint256 fromDate,
        uint256 toDate
    ) internal view returns (bool) {
        uint256[] memory bookedDates = roomToDates[roomNumber];
        
        // Find the first index where the date is >= current date
        uint256 startIndex = findFirstFutureDateIndex(bookedDates, block.timestamp);
        
        for (uint256 i = startIndex; i < bookedDates.length; i++) {
            uint256 tokenId = bookedDates[i];
            DateRange memory existingRange = tokenToDateRange[tokenId];
            if (
                (fromDate < existingRange.toDate && toDate > existingRange.fromDate) &&
                existingRange.roomNumber == roomNumber
            ) {
                return true;
            }
        }
        return false;
    }

    // Binary search function to find the first future date index
    function findFirstFutureDateIndex(uint256[] memory dates, uint256 currentTimestamp) internal pure returns (uint256) {
        uint256 low = 0;
        uint256 high = dates.length;
        
        while (low < high) {
            uint256 mid = low + (high - low) / 2;
            if (dates[mid] < currentTimestamp) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return low;
    }


    // Override tokenURI to return the metadata URI from storage
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return tokenMetadataURIs[tokenId];
    }
}