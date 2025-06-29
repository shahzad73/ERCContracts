// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract DateRangeContract {
    struct DateRange {
        uint256 fromDate;
        uint256 toDate;
    }

    mapping(uint256 => DateRange) public dateRanges;  // Key is the `fromDate`
    uint256[] public sortedKeys;  // Sorted list of fromDates for quick lookup

    // Add a new date range if it doesn't overlap with adjacent ranges
    function addDateRange(uint256 _fromDate, uint256 _toDate) public {
        require(_fromDate < _toDate, "Invalid date range");

        // Check if new range overlaps with previous or next range
        uint256 prevKey = findPreviousKey(_fromDate);
        uint256 nextKey = findNextKey(_fromDate);

        require(
            (prevKey == 0 || dateRanges[prevKey].toDate < _fromDate) &&
            (nextKey == 0 || _toDate < dateRanges[nextKey].fromDate),
            "Overlapping date range"
        );

        // Add the new range
        dateRanges[_fromDate] = DateRange(_fromDate, _toDate);
        sortedKeys.push(_fromDate);
    }

    // Helper to find the previous key in sorted keys
    function findPreviousKey(uint256 key) internal view returns (uint256) {
        if (sortedKeys.length == 0) return 0;

        uint256 idx = 0;
        while (idx < sortedKeys.length && sortedKeys[idx] < key) {
            idx++;
        }
        return (idx > 0) ? sortedKeys[idx - 1] : 0;
    }

    // Helper to find the next key in sorted keys
    function findNextKey(uint256 key) internal view returns (uint256) {
        if (sortedKeys.length == 0) return 0;

        for (uint256 i = 0; i < sortedKeys.length; i++) {
            if (sortedKeys[i] > key) {
                return sortedKeys[i];
            }
        }
        return 0;
    }

}


