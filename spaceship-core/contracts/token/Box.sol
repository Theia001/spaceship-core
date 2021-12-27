// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../utils/ERC721Extra.sol";
import "../utils/Operator.sol";

contract Box is ERC721Extra("SpaceShip.Box", "Box"), Operator {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 public constant TYPE_U = 1;
    uint256 public constant TYPE_S = 2;
    uint256 public uLimit = 10000;
    mapping(uint256 => uint256) public typeNumAll;
    mapping(uint256 => uint256) public boxCreateSalt;

    constructor(string memory _uri) public {
        _setBaseURI(_uri);
    }

    function mint(address _to, uint256 _type) public onlyOperator {
        require(_type == TYPE_U || _type == TYPE_S, "Box: invalid type");

        // u box has num limit
        if (_type == TYPE_U) {
            require(typeNumAll[_type] < uLimit, "Box: u box is over limit");
        }

        typeNumAll[_type] += 1;
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mintType(_to, newTokenId, _type);
        boxCreateSalt[newTokenId] = block.number;
    }

    // only time lock to set
    function setULimit(uint256 _limit) public onlyOwner {
        uLimit = _limit;
    }

    // only time lock to set
    function setBaseURI(string memory _uri) public onlyOwner {
        _setBaseURI(_uri);
    }

}
