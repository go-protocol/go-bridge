pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./BridgeStorage.sol";

contract BridgeLogic {
    using SafeMath for uint256;

    string public constant name = "BridgeLogic";

    /// @dev keccak256(abi.encodePacked('operator'))
    bytes32 internal constant OPERATORHASH = 0x46a52cf33029de9f84853745a87af28464c80bf0346df1b32e205fc73319f622;
    uint256 public constant TASKINIT = 0;
    uint256 public constant TASKPROCESSING = 1;
    uint256 public constant TASKCANCELLED = 2;
    uint256 public constant TASKDONE = 3;
    uint256 public constant WITHDRAWTASK = 1;

    address private caller;
    BridgeStorage private store;

    constructor(address aCaller) {
        caller = aCaller;
    }

    modifier onlyCaller() {
        require(msg.sender == caller, "only main contract can call");
        _;
    }

    modifier operatorExists(address operator) {
        require(store.supporterExists(OPERATORHASH, operator), "wrong operator");
        _;
    }

    function resetStoreLogic(address storeAddress) external onlyCaller {
        store = BridgeStorage(storeAddress);
    }

    function getStoreAddress() public view returns (address) {
        return address(store);
    }

    /**
     * @dev 设置支持的任务
     * @param taskType 
     * @param taskHash 
     * @param oneAddress 
     * @param requireNum 
     * @notice 
     */
    function supportTask(
        uint256 taskType,
        bytes32 taskHash,
        address oneAddress,
        uint256 requireNum
    ) external onlyCaller returns (uint256) {
        require(!store.supporterExists(taskHash, oneAddress), "supporter already exists");
        (uint256 theTaskType, uint256 theTaskStatus, uint256 theSupporterNum) = store.getTaskInfo(taskHash);
        require(theTaskStatus < TASKDONE, "wrong status");

        if (theTaskStatus != TASKINIT) require(theTaskType == taskType, "task type not match");
        store.addSupporter(taskHash, oneAddress);
        theSupporterNum++;
        if (theSupporterNum >= requireNum) theTaskStatus = TASKDONE;
        else theTaskStatus = TASKPROCESSING;
        store.setTaskInfo(taskHash, taskType, theTaskStatus);
        return theTaskStatus;
    }

    function cancelTask(bytes32 taskHash) external onlyCaller returns (uint256) {
        (uint256 theTaskType, uint256 theTaskStatus, uint256 theSupporterNum) = store.getTaskInfo(taskHash);
        require(theTaskStatus == TASKPROCESSING, "wrong status");
        if (theSupporterNum > 0) store.removeAllSupporter(taskHash);
        theTaskStatus = TASKCANCELLED;
        store.setTaskInfo(taskHash, theTaskType, theTaskStatus);
        return theTaskStatus;
    }

    function removeTask(bytes32 taskHash) external onlyCaller {
        store.removeTask(taskHash);
    }
}
