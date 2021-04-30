pragma solidity ^0.7.0;

contract Container {
    struct Item {
        uint256 itemType;
        uint256 status;
        address[] addresses;
    }

    uint256 MaxItemAdressNum = 255;
    mapping(bytes32 => Item) private container;

    // bool private _nativePaused = false;

    
    /**
     * @dev 判断item地址是否存在
     * @param _id item的hash值
     * @param _oneAddress 地址
     */
    function itemAddressExists(bytes32 _id, address _oneAddress) internal view returns (bool) {
        // 遍历classHashArray数组，寻找hash值
        for (uint256 i = 0; i < container[_id].addresses.length; i++) {
            if (container[_id].addresses[i] == _oneAddress) return true;
        }
        return false;
    }

    function getItemAddresses(bytes32 _id) internal view returns (address[] memory) {
        return container[_id].addresses;
    }

    function getItemInfo(bytes32 _id)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (container[_id].itemType, container[_id].status, container[_id].addresses.length);
    }

    /**
     * @dev 返回item地址长度
     * @param _id 任务hash
     */
    function getItemAddressCount(bytes32 _id) internal view returns (uint256) {
        return container[_id].addresses.length;
    }

    function setItemInfo(
        bytes32 _id,
        uint256 _itemType,
        uint256 _status
    ) internal {
        container[_id].itemType = _itemType;
        container[_id].status = _status;
    }

    /**
     * @dev 添加item地址
     * @param _id 任务hash
     * @param _oneAddress 地址
     */
    function addItemAddress(bytes32 _id, address _oneAddress) internal {
        // 确认任务hash对应地址记录不存在
        require(!itemAddressExists(_id, _oneAddress), "dup address added");
        // 确认任务地址数组长度小于最大地址长度
        require(container[_id].addresses.length < MaxItemAdressNum, "too many addresses");
        // 在任务id对应的地址数组中推入地址
        container[_id].addresses.push(_oneAddress);
    }

    function removeItemAddresses(bytes32 _id) internal {
        delete container[_id].addresses;
    }

    function removeOneItemAddress(bytes32 _id, address _oneAddress) internal {
        for (uint256 i = 0; i < container[_id].addresses.length; i++) {
            if (container[_id].addresses[i] == _oneAddress) {
                container[_id].addresses[i] = container[_id].addresses[container[_id].addresses.length - 1];
                container[_id].addresses.pop();
                return;
            }
        }
    }

    /**
     * @dev 删除item
     * @param _id 任务hash
     */
    function removeItem(bytes32 _id) internal {
        delete container[_id];
    }

    /**
     * @dev 替换item地址
     * @param _id 任务hash
     * @param _oneAddress 地址
     * @param _anotherAddress 替换地址
     */
    function replaceItemAddress(
        bytes32 _id,
        address _oneAddress,
        address _anotherAddress
    ) internal {
        // 遍历数组地址，替换地址
        for (uint256 i = 0; i < container[_id].addresses.length; i++) {
            if (container[_id].addresses[i] == _oneAddress) {
                container[_id].addresses[i] = _anotherAddress;
                return;
            }
        }
    }
}
