// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./USDCInterface.sol";

contract Payroll {

    address companyManager;

    uint8 employeeCount = 1;

    bytes32 rootHash;

    bool intialState;

    USDCInterface public usdcContractAddress;

    uint256 tokenBalance;

    uint256 public constant numberofDays = 30 days; //pay days

    enum EmployeeLevel{
        Junior,
        Intermediate,
        Senior
    }

    struct EmployeeInfo{
        string name;
        address employeeAddress;
        string post;
        EmployeeLevel level;
        uint timeFilled;
        bool registered;
        bool approved;
    }

    EmployeeInfo[] _employeeInfo;
    address[] EmployeeAddress;
    address[]approvedEmployeeAddress;
    mapping(address => EmployeeInfo) info;

    struct SalaryInvoice{
        string name;
        address employeeAddress;
        string post;
        EmployeeLevel level;
        uint time;
        uint amountTobepaid;
        uint ratePerDay;
        string description;
        uint extraWorkFee;
        bool approved;
        bool set;
    }

    mapping(address => SalaryInvoice) _salaryInvoice;


    /////////////EVENTS////////////////
    event Registered(address indexed caller, uint256 time);
    event Deposit(address indexed depositor, uint256 indexed amount);
    event Withdrawal(address indexed employee, uint256 indexed amount, uint256 indexed nextwithdrawal);
    event ManagerUpdated( address indexed oldCompanyManager, address indexed companyManager, uint256 time);


    ///////////ERROR MESSAGE///////////
    error NotVerified();
    
    error  TimeNotReached();

    error ZeroAmount();

    error NotWhitelisted();

    error InsufficientFunds();

    error NotManager();

    error AddressZero();

    error AlreadyInitialized();

    error AlreadyRegistered();

    error NotApproved();

    constructor(address _companyManager,USDCInterface _contractAddr, bytes32 _rootHash) {
        companyManager = _companyManager;
        usdcContractAddress = _contractAddr;
        rootHash = _rootHash;
    }

     ///////////////FUNCTIONS///////////////


    // /// @dev initialise function serves as the contract constructor
    // function initialise(address _companyManager, bytes32 _rootHash) external{
    //     if(intialState == true){
    //         revert AlreadyInitialized();
    //     }
    //     companyManager = _companyManager;
    //     intialState = true;
    //     rootHash = _rootHash; 
    // }

    function registerInfo(string memory _name, address _employeeAddress, string memory _post, EmployeeLevel _level) external returns(string memory){
        if(_employeeAddress == address(0)){
            revert AddressZero();
        }
        EmployeeInfo storage EI = info[_employeeAddress];
        if(EI.registered == true){
            revert AlreadyRegistered();
        }
        EI.name = _name;
        EI.employeeAddress = _employeeAddress;
        EI.post = _post;
        EI.level = _level; //0 || 1 || 2
        EI.timeFilled = block.timestamp;
        EI.registered = true;
        EmployeeAddress.push(_employeeAddress);

        emit Registered(_employeeAddress, block.timestamp);
        return "Registration successful, Reviewing....";
    }

    function reviewEmployee(address _employeeAddress) external returns(address[] memory){
        if(msg.sender != companyManager){
            revert NotManager();
        }
        EmployeeInfo storage EI = info[_employeeAddress];
        //check
        EI.approved = true;
        employeeCount = employeeCount + 1;
        approvedEmployeeAddress.push(_employeeAddress);

    }

    function fillSalaryInvoice(string memory _name, string memory _post, EmployeeLevel _level, uint256 amount, string memory _description, uint256 rate, uint256 _extrafee) external returns(string memory) {
        // if(numberofDays != 30 days){
        //     revert TimeNotReached();
        // }

        EmployeeInfo memory EI = info[msg.sender];
        if( EI.approved == false ){
            revert NotVerified();
        }
        SalaryInvoice storage invoice = _salaryInvoice[msg.sender];
        require(invoice.set == true, "salary not set");
        invoice.name = _name;
        invoice.employeeAddress = msg.sender;
        invoice.post = _post;
        invoice.level = _level; //0 || 1 || 2
        invoice.description = _description;
        if(invoice.amountTobepaid != amount){
            revert("amount doesn't correlate");
        }
        invoice.time = block.timestamp;
        if(invoice.ratePerDay != rate){
            revert("rate doesn't correlate");
        }
        if(invoice.extraWorkFee != _extrafee){
            revert("fee doesn't correlate");
        }

        return "Salary Invoice filled Successfully";

    }

    function reviewSalaryInvoice(address _employeeAddress) external {
         if (msg.sender != companyManager) {
            revert NotManager();
        } 
         SalaryInvoice storage invoice = _salaryInvoice[_employeeAddress];
        //approves if all information entered by the employee is valid

    }

    function setEmployeeSalary(address _employeeAddress, uint256 amount, uint256 _rate, uint256 extrafee) external {
         if (msg.sender != companyManager) {
            revert NotManager();
        } 
        //only approved employees
         EmployeeInfo memory EI = info[_employeeAddress];
        if( EI.approved == false ){
            revert NotApproved();
        }
        SalaryInvoice storage invoice = _salaryInvoice[_employeeAddress];
        invoice.amountTobepaid = amount;
        invoice.time = block.timestamp;
        invoice.ratePerDay = _rate;
        invoice.extraWorkFee = extrafee;
        invoice.set = true;
    }


    ///@dev function changes the former companymanager, only callable by the previous manager
      function changeCompanyManager(address _companyManager) external{
        if (msg.sender != companyManager) {
            revert NotManager();
        } 
        address oldCompanyManager = companyManager;
        companyManager = _companyManager;

        emit ManagerUpdated(oldCompanyManager, companyManager, block.timestamp);
    }


    /// @notice function returns the level of an employee
    function getEmployeeStatus(address _employeeAddress) external view returns(EmployeeLevel){
        EmployeeInfo memory EI = info[_employeeAddress];
        if( EI.approved == false ){
            revert NotVerified();
        }
        return EI.level;
    }

    /* @dev Gets the total number of employees registered in the payroll */
    function getEmployeeCount() external view returns(uint){
        return employeeCount;
    }     
    

    function verified(bytes32[] memory proof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, rootHash, leaf);
    }

    function deposit(uint256 amount) external{
        if(amount <= 0){
            revert ZeroAmount();
        }
        bool success = usdcContractAddress.transferFrom(msg.sender, address(this), amount);
        require(success, "Not successful");
        tokenBalance += amount;

        emit Deposit(msg.sender, amount);
    }

    function withdraw(bytes32[] memory proof) external {
        require(USDCInterface(usdcContractAddress).balanceOf(address(this)) > 0, "Contract Not funded");
        bool prove = verified(proof);
        if (prove) {
            revert NotWhitelisted();
        }
    
    }

    function withdrawContractBal(address to) public payable {
         if (msg.sender != companyManager) {
            revert NotManager();
            }
        if(address(this).balance < msg.value){
            revert InsufficientFunds();
        } else{
            uint256 amountTosend = address(this).balance - msg.value;
            payable(to).transfer(amountTosend);
        }
    }

    receive() external payable{}
}
