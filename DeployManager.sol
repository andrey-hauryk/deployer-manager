// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./IUtilityContract.sol";

contract DeployManager is Ownable {

    constructor() Ownable(msg.sender) {}

    event newContractAdd(address _contractAdress, uint256 _fee, bool _isActive, uint256 _timestamp);
    event contractFeeUpdated(address _contractAdress, uint256 _oldFee, uint256 _newFee, uint256 _timestamp);
    event ContractStatusUpdated(address _contractAdress, bool _isActive, uint256 _timestamp);
    event newDeployment( address _deployer, address _contractAdress, uint256 _fee, uint256 _timestamp);


    error ContractNotReady();
    error NotEnoughFunds();
    error ContractNotExist();
    error InitializationFailed();
    error ContractNotRegistered();

    struct ContractInfo {
        uint256 fee;
        bool isActive;
        uint256 registredAt;
    }

    mapping(address => address[]) public deployedContracts;
    mapping(address => ContractInfo) public contractsData;

    function deploy(address _utilityContract, bytes calldata _initData) external  payable returns(address) {
        ContractInfo memory info = contractsData[_utilityContract];
        require(msg.value >= info.fee, NotEnoughFunds()) ; 
        require(info.isActive, ContractNotReady());
        require(info.registredAt > 0, ContractNotExist());

        address clone = Clones.clone(_utilityContract);

        require(IUtilityContract(clone).initialize(_initData), InitializationFailed());

        payable(owner()).transfer(msg.value);

        deployedContracts[msg.sender].push(clone);

        emit newDeployment(msg.sender, clone, msg.value, block.timestamp);

        return clone;
    }

    function addNewContract(address _contractAddress, uint256 _fee, bool _isActive) external onlyOwner {
        contractsData[_contractAddress] = ContractInfo({
            fee: _fee,
            isActive: _isActive,
            registredAt: block.timestamp
        });

        emit newContractAdd(_contractAddress, _fee, _isActive, block.timestamp);
    }

    function updateFee(address _contractAddress, uint256 _newFee) external onlyOwner {
        require(contractsData[_contractAddress].registredAt > 0, ContractNotRegistered());
        uint256 _oldFee = contractsData[_contractAddress].fee;
        contractsData[_contractAddress].fee = _newFee;
        emit contractFeeUpdated(_contractAddress, _oldFee, _newFee, block.timestamp);
    }

    function deactivateContract(address _contractAddress) external onlyOwner {
        require(contractsData[_contractAddress].registredAt > 0, ContractNotRegistered());
        contractsData[_contractAddress].isActive = false;
        emit ContractStatusUpdated(_contractAddress, false, block.timestamp);
    }

    function activateContract(address _contractAddress) external onlyOwner {
        require(contractsData[_contractAddress].registredAt > 0, ContractNotRegistered());
        contractsData[_contractAddress].isActive = true;
        emit ContractStatusUpdated(_contractAddress, true, block.timestamp);
    }
}