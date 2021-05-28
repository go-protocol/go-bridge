const Bridge = artifacts.require("Bridge");
const BridgeLogic = artifacts.require("BridgeLogic");
const BridgeStorage = artifacts.require("BridgeStorage");


module.exports = async (deployer, network, accounts) => {
    const owner = accounts[0];
    const operator1 = accounts[1];
    const operator2 = accounts[2];
    let param = [[owner], "1"];
    await deployer.deploy(Bridge,...param);
    param = [Bridge.address];
    await deployer.deploy(BridgeLogic,...param);
    param = [BridgeLogic.address];
    await deployer.deploy(BridgeStorage,...param);
    const BridgeInstance = await Bridge.deployed()
    // 暂停合约
    let receipt = await BridgeInstance.pause();
    console.log(receipt)
    // 设置logic
    param = [
        "logic", // class
        BridgeLogic.address,
        BridgeLogic.address,
    ];
    receipt = await BridgeInstance.modifyAdminAddress(...param);
    console.log(receipt)
    // 设置store
    param = [
        "store", // class
        BridgeStorage.address,
        BridgeStorage.address,
    ];
    receipt = await BridgeInstance.modifyAdminAddress(...param);
    console.log(receipt)
    // 设置operator1
    param = [
        "operator", // class
        operator1,
    ];
    receipt = await BridgeInstance.addAddress(...param);
    console.log(receipt)
    // 设置operator2
    param = [
        "operator", // class
        operator2,
    ];
    receipt = await BridgeInstance.addAddress(...param);
    console.log(receipt)
    // 取消暂停合约
    receipt = await BridgeInstance.unpause();
    console.log(receipt)
};