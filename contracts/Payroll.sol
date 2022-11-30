// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

contract Payroll {

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
    }

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
    }
}
