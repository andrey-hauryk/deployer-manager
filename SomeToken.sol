// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "./IUtilityContract.sol";

contract SomeToken is IUtilityContract {

    uint256 public number;
    address public someToken;

    error AlreadyInitialized();

    modifier notInitialized() {
        require(!initialized, AlreadyInitialized());
        _;
    }

    bool private initialized;

    constructor() {}

    function initialize(bytes memory _initData) external notInitialized returns(bool) {
        (uint256 _number, address _someToken) = abi.decode(_initData, (uint256, address));
        
        number = _number;
        someToken = _someToken;

        initialized = true;

        return(true); 
    }

    function getInitData(uint256 _number, address _bigBoss) external pure returns(bytes memory) {
        return abi.encode(_number, _bigBoss);
    }

    function doSmth() external view returns(uint256, address) {
        return (number, someToken);
    }
}