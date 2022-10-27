//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SecondLayer{
    uint256 n;
    uint256 m;
    uint256 p;

    uint256 firstRegister;
    uint256 secondRegister;
    uint256 control;

    mapping (address => uint256) nonce;
    mapping (uint256 => uint256) cell;

    constructor(uint256 n_, uint256 m_, uint256 p_){
        n = n_;
        m = m_;
        p = p_;

        firstRegister =1;
        secondRegister = 1;
        control = 1;
    }

    function getGenerator() public view returns (uint256){
        return uint256(uint160(msg.sender)) ** (nonce[msg.sender] + 1);
    }

    function deposit(uint256 fRegister,uint256 sRegister) payable public{
        uint256 generator = getGenerator();
        cell[generator] = msg.value;
        uint256 c = generator ** ((p-1)*(n-1));
        require(mulmod((fRegister ** m) , c,p) == (sRegister ** n) % p, "INVALID CONDITION");
        firstRegister = mulmod(firstRegister, fRegister, p);
        secondRegister = mulmod(secondRegister, sRegister, p);
        control = mulmod(control, c, p);
    }

    function saveBlock(uint256 fRegister,uint256 sRegister) public{
        require(mulmod((fRegister ** m) , control,p) == (sRegister ** n) % p, "INVALID CONDITION");
        firstRegister = mulmod(firstRegister, fRegister, p);
        secondRegister = mulmod(secondRegister, sRegister, p);
    }

    function withdrawal(uint256 generator,uint256 fRegister,uint256 sRegister,uint256 v) public{
        require(mulmod((fRegister ** m) , control,p) == (sRegister ** n) % p, "INVALID CONDITION");
        require(generator ** (v* uint256(uint160(msg.sender))) % p == 1, "INVALID CONDITION");
        firstRegister = mulmod(firstRegister, fRegister, p);
        secondRegister = mulmod(secondRegister, sRegister, p);
        uint256 eth = cell[generator];
        cell[generator] = 0;
        payable(msg.sender).transfer(eth);
    }
}