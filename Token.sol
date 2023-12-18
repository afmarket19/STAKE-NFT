// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

contract TokenMusic is ERC20, Ownable {
    using SafeERC20 for IERC20;

    uint256 public maxSupply;
    uint256 public initSupply;
    uint256 public poolSupply;
    address public taxWallet1;
    address public taxWallet2;
    uint256 public buyTaxRate;
    uint256 public sellTaxRate;

    bool public tradingEnabled = true;
    mapping(address => bool) public frozenAccounts;

    uint8 private _decimals = 18;

    constructor() ERC20("MOVE TOKEN", "MOVE") {
        maxSupply = 10000000000 * (10 ** _decimals);
        initSupply = (maxSupply * 8) / 100;
        poolSupply = maxSupply - initSupply;
        taxWallet1 = address(0xYourAddress1); // Gantilah dengan alamat wallet pertama
        taxWallet2 = address(0xYourAddress2); // Gantilah dengan alamat wallet kedua
    }


        _mint(msg.sender, initSupply);
        _mint(msg.sender, poolSupply);
    }

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event TradingEnabled(bool enabled);
    event Freeze(address target, bool frozen);

    // Fungsi untuk mengatur pajak dan wallet penampung
    function setTaxSettings(uint256 _buyTaxRate, uint256 _sellTaxRate) external onlyOwner {
        require(_buyTaxRate + _sellTaxRate <= 100, "Total tax rate exceeds 100%");
        buyTaxRate = _buyTaxRate;
        sellTaxRate = _sellTaxRate;
    }

    // Override fungsi transfer dengan logika pajak
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(!frozenAccounts[msg.sender], "Sender account is frozen");
        require(tradingEnabled, "Trading is disabled");
        
        uint256 taxAmount = 0;
        if (msg.sender != taxWallet1 && msg.sender != taxWallet2) {
            taxAmount = (amount * buyTaxRate) / 100;
            super.transfer(taxWallet1, (taxAmount * 75) / 100);
            super.transfer(taxWallet2, (taxAmount * 25) / 100);
        }
        
        uint256 transferAmount = amount - taxAmount;
        return super.transfer(recipient, transferAmount);
    }

    // Fungsi untuk mengaktifkan/menonaktifkan trading
    function setTradingEnabled(bool _enabled) external onlyOwner {
        tradingEnabled = _enabled;
        emit TradingEnabled(_enabled);
    }

    // Memanggil fungsi untuk membekukan akun
    function freezeAccount(address _account) external onlyOwner {
    frozenAccounts[_account] = true;
    emit Freeze(_account, true);
    }

    // Memanggil fungsi untuk membuka pembekuan akun
    function unfreezeAccount(address _account) external onlyOwner {
    frozenAccounts[_account] = false;
    emit Freeze(_account, false);
    }

    // Fungsi pemulihan token
    function recoveryToken(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    // Fungsi penarikan
    function withdrawPayable() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
