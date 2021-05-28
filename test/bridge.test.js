const { contract, accounts, web3 } = require("@openzeppelin/test-environment");
const { ether, constants, expectEvent } = require("@openzeppelin/test-helpers");
const assert = require("assert");
const ERC20Contract = contract.fromArtifact("ERC20FixedSupply");
const BridgeContract = contract.fromArtifact("Bridge");
const BridgeLogicContract = contract.fromArtifact("BridgeLogic");
const BridgeStorageContract = contract.fromArtifact("BridgeStorage");

const totalSupply = "10000"; //发行总量
const amount = "1000"; //存款量
let tx = "";
let _target = "";
const chain = "heco";
const selector = "mint(address,uint256)";
[deployer, sender, operator1, operator2, pauser, owner, target] = accounts;

describe("固定总量代币", function () {
    it("布署代币合约", async function () {
        ERC20Param = [
            "Token A", //代币名称
            "AAA", //代币缩写
            totalSupply, //发行总量
        ];
        TokenA = await ERC20Contract.new(...ERC20Param, { from: deployer });
    });

    it("布署代币合约", async function () {
        ERC20Param = [
            "TokenB", //代币名称
            "BBB", //代币缩写
            0, //发行总量
        ];
        TokenB = await ERC20Contract.new(...ERC20Param, { from: deployer });
    });
});
describe("部署合约", function () {
    it("部署Bridge", async function () {
        param = [[deployer], "1"];
        BridgeInstance = await BridgeContract.new(...param, { from: deployer });
    });
    it("部署Logic", async function () {
        param = [BridgeInstance.address];
        BridgeLogicInstance = await BridgeLogicContract.new(...param, {
            from: deployer,
        });
    });
    it("部署Storage", async function () {
        param = [BridgeLogicInstance.address];
        BridgeStorageInstance = await BridgeStorageContract.new(...param, {
            from: deployer,
        });
    });
});

describe("初始化", function () {
    it("暂停合约: pause()", async function () {
        let receipt = await BridgeInstance.pause({ from: deployer });
        expectEvent(receipt, "Paused", {
            account: deployer,
        });
    });
    it("设置Logic地址: modifyAdminAddress()", async function () {
        param = [
            "logic", // class
            BridgeLogicInstance.address,
            BridgeLogicInstance.address,
        ];
        let receipt = await BridgeInstance.modifyAdminAddress(...param, {
            from: deployer,
        });
        expectEvent(receipt, "AdminChanged", {
            TaskType: "modifyAddress",
            class: "logic",
            oldAddress: BridgeLogicInstance.address,
            newAddress: BridgeLogicInstance.address,
        });
    });
    it("设置Storage地址: modifyAdminAddress()", async function () {
        param = [
            "store", // class
            BridgeStorageInstance.address,
            BridgeStorageInstance.address,
        ];
        let receipt = await BridgeInstance.modifyAdminAddress(...param, {
            from: deployer,
        });
        expectEvent(receipt, "AdminChanged", {
            TaskType: "modifyAddress",
            class: "store",
            oldAddress: BridgeStorageInstance.address,
            newAddress: BridgeStorageInstance.address,
        });
    });
    it("设置Operator1地址: addAddress()", async function () {
        param = [
            "operator", // class
            operator1,
        ];
        let receipt = await BridgeInstance.addAddress(...param, { from: deployer });
        expectEvent(receipt, "AdminChanged", {
            TaskType: "addAddress",
            class: "operator",
            oldAddress: operator1,
            newAddress: operator1,
        });
    });
    it("设置Operator2地址: addAddress()", async function () {
        param = [
            "operator", // class
            operator2,
        ];
        let receipt = await BridgeInstance.addAddress(...param, { from: deployer });
        expectEvent(receipt, "AdminChanged", {
            TaskType: "addAddress",
            class: "operator",
            oldAddress: operator2,
            newAddress: operator2,
        });
    });
    it("取消暂停合约: unpause()", async function () {
        let receipt = await BridgeInstance.unpause({ from: deployer });
        expectEvent(receipt, "Unpaused", {
            account: deployer,
        });
    });
    it("设置Pauser地址: addAddress()", async function () {
        param = [
            "pauser", // class
            pauser,
        ];
        let receipt = await BridgeInstance.addAddress(...param, { from: deployer });
        expectEvent(receipt, "AdminChanged", {
            TaskType: "addAddress",
            class: "pauser",
            oldAddress: pauser,
            newAddress: pauser,
        });
    });
    it("设置Owner地址: addAddress()", async function () {
        param = [
            "owner", // class
            owner,
        ];
        let receipt = await BridgeInstance.addAddress(...param, { from: deployer });
        expectEvent(receipt, "AdminChanged", {
            TaskType: "addAddress",
            class: "owner",
            oldAddress: owner,
            newAddress: owner,
        });
    });
    it("取消原Pauser: dropAddress()", async function () {
        param = [
            "pauser", // class
            deployer,
        ];
        let receipt = await BridgeInstance.dropAddress(...param, { from: deployer });
        expectEvent(receipt, "AdminChanged", {
            TaskType: "dropAddress",
            class: "pauser",
            oldAddress: deployer,
            newAddress: deployer,
        });
    });
    it("取消原Owner: dropAddress()", async function () {
        param = [
            "owner", // class
            deployer, // address
        ];
        let receipt = await BridgeInstance.dropAddress(...param, { from: deployer });
        expectEvent(receipt, "AdminChanged", {
            TaskType: "dropAddress",
            class: "owner",
            oldAddress: deployer,
            newAddress: deployer,
        });
    });
    it("添加TokenB铸币权: addMinter()", async function () {
        let receipt = await TokenB.transferOwnership(BridgeInstance.address, {
            from: deployer,
        });
        expectEvent(receipt, "OwnershipTransferred", {
            previousOwner: deployer,
            newOwner: BridgeInstance.address,
        });
    });
    it("设置取款Selector: setWithdrawSelector()", async function () {
        param = [
            TokenB.address, // token
            selector, // method
            false, //_isValueFirst
        ];
        await BridgeInstance.setWithdrawSelector(...param, { from: operator1 });
    });
    it("验证Logic地址: getLogicAddress()", async function () {
        assert.equal(
            BridgeLogicInstance.address,
            await BridgeInstance.getLogicAddress()
        );
    });
    it("验证Storage地址: getStoreAddress()", async function () {
        assert.equal(
            BridgeStorageInstance.address,
            await BridgeInstance.getStoreAddress()
        );
    });
});

describe("存款", function () {
    it("发送: transfer()", async function () {
        let receipt = await TokenA.transfer(sender, ether(amount), {
            from: deployer,
        });
        expectEvent(receipt, "Transfer", {
            from: deployer,
            to: sender,
            value: ether(amount),
        });
    });
    it("验证余额: balanceOf()", async function () {
        assert.equal(
            ether(amount).toString(),
            (await TokenA.balanceOf(sender)).toString()
        );
    });
    it("批准: approve()", async function () {
        let receipt = await TokenA.approve(BridgeInstance.address, ether(amount), {
            from: sender,
        });
        expectEvent(receipt, "Approval", {
            owner: sender,
            spender: BridgeInstance.address,
            value: ether(amount),
        });
    });
    it("验证批准: allowance()", async function () {
        assert.equal(
            ether(amount),
            (await TokenA.allowance(sender, BridgeInstance.address)).toString()
        );
    });
    it("存款: depositToken()", async function () {
        _target = target.toString().replace(/0x/g, "");
        param = [
            TokenA.address, // _token
            ether(amount), // value
            _target, // _targetAddress
            chain, // chain
        ];
        let receipt = await BridgeInstance.depositToken(...param, {
            from: sender,
        });
        tx = receipt.tx.replace(/0x/g, "");
        expectEvent(receipt, "DepositToken", {
            value: ether(amount),
            targetAddress: _target,
            chain: chain,
            nativeValue: "0",
        });
    });
    it("验证TokenA余额: balanceOf()", async function () {
        assert.equal("0", (await TokenA.balanceOf(sender)).toString());
    });
    it("验证TokenB余额: balanceOf()", async function () {
        assert.equal("0", (await TokenB.balanceOf(target)).toString());
    });
    it("取款: withdrawToken() operator1", async function () {
        let _TokenA = TokenA.address.replace(/0x/g, "");
        let proof = chain + "_" + _TokenA + "_" + tx + "_" + "1";
        let taskHash = web3.utils.keccak256(
            web3.utils.encodePacked(target, ether(amount), proof)
        );
        param = [
            TokenB.address, // _token
            target, // to
            ether(amount), // value
            proof, // proof
            taskHash, // taskHash
        ];
        let receipt = await BridgeInstance.withdrawToken(...param, {
            from: operator1,
        });
        expectEvent(receipt, "WithdrawingToken", {
            to: target,
            token: TokenB.address,
            value: ether(amount),
            proof: proof,
        });
    });
    it("取款: withdrawToken() operator2", async function () {
        let _TokenA = TokenA.address.replace(/0x/g, "");
        let proof = chain + "_" + _TokenA + "_" + tx + "_" + "1";
        let taskHash = web3.utils.keccak256(
            web3.utils.encodePacked(target, ether(amount), proof)
        );
        param = [
            TokenB.address, // _token
            target, // to
            ether(amount), // value
            proof, // proof
            taskHash, // taskHash
        ];
        let receipt = await BridgeInstance.withdrawToken(...param, {
            from: operator2,
        });
        expectEvent(receipt, "WithdrawingToken", {
            to: target,
            token: TokenB.address,
            value: ether(amount),
            proof: proof,
        });
        expectEvent(receipt, "WithdrawDoneToken", {
            to: target,
            token: TokenB.address,
            value: ether(amount),
            proof: proof,
        });
    });
    it("验证TokenB余额: balanceOf()", async function () {
        assert.equal(
            ether(amount).toString(),
            (await TokenB.balanceOf(target)).toString()
        );
    });
});
