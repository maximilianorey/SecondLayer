//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestERC721 is ERC721{
    constructor(string memory _name,string memory _symbol) ERC721(_name,_symbol){
    }

    function mint(address to, uint256 tokenId) public{
        _mint(to,tokenId);
    }
}