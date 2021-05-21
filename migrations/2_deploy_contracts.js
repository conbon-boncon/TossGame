const TossGame = artifacts.require("TossGame");

module.exports = function (deployer) {
  deployer.deploy(TossGame, {value: "1000000000000000000" });
};
