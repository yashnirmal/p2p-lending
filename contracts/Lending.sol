// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Lending {
    address public owner;

    struct Loan {
        uint256 id;
        address lender;
        uint256 amount;
        uint256 interestRate;
        uint256 dueTime;
        string status; // Possible values: "listed", "given", "repaid"
    }

    struct LoanRequest {
        uint256 id;
        uint256 loanId;
        address borrower;
        uint256 creditScore;
        string status; // Possible values: "pending", "approved", "declined", "repaid"
    }

    Loan[] public allLoans; 
    LoanRequest[] public allLoanRequests; 

    mapping(address => Loan[]) public lenderLoans;

    mapping(address => LoanRequest[]) public loanRequests;
    
    mapping(address => uint256) public creditScore;

    constructor() {
        owner = msg.sender;
    }
    
    function getAllLoans() public returns (Loan[] memory) {
        if(creditScore[msg.sender]==0){
            creditScore[msg.sender] = 600;
        }
        return allLoans;
    }
    
    function getAllLoanRequests() view public returns (LoanRequest[] memory) {
        return allLoanRequests;
    }
    
    
    function getCreditScore() view external returns (uint256){
        return creditScore[msg.sender];
    }

    function listLoan(uint256 _amount, uint256 _interestRate, uint256 _dueTime) external {
        // Get the current length of the 'allLoans' array as the new loan ID
        uint256 loanId = allLoans.length;

        // Calculate the due date by adding '_dueTime' days to the current timestamp
        uint256 dueDate = block.timestamp + (_dueTime * 1 days);

        // Create a new Loan struct with the provided information
        Loan memory newLoan = Loan({
            id: loanId,
            lender: msg.sender,
            amount: _amount,
            interestRate: _interestRate,
            dueTime: dueDate,
            status: "listed"
        });

        // Add the new loan to the 'allLoans' array
        allLoans.push(newLoan);

        // Add the new loan to the lender's 'lenderLoans' list
        lenderLoans[msg.sender].push(newLoan);
    }


    function getLenderLoans() external view returns (Loan[] memory) {
        Loan[] memory temp = lenderLoans[msg.sender];
        return temp;
    }

    function requestLoan(uint256 _loanId) external {
        require(_loanId < allLoans.length, "Invalid loan ID");
        uint256 _id = allLoanRequests.length;
        if(creditScore[msg.sender]==0){
            creditScore[msg.sender] = 600;
        }
        LoanRequest memory newLoanRequest = LoanRequest({
            id : _id,
            loanId: _loanId,
            borrower : msg.sender,
            creditScore: creditScore[msg.sender],
            status: "pending"
        });
        allLoanRequests.push(newLoanRequest);
        loanRequests[msg.sender].push(newLoanRequest);
    }
    

    function getBorrowerLoanRequests() external view returns (LoanRequest[] memory) {
        return loanRequests[msg.sender];
    }

    function approveLoanRequest(uint256 _id) external payable {
        require(_id < allLoanRequests.length, "Invalid loan ID");
        // require(msg.value>=allLoans[allLoanRequests[_id].loanId].amount,"Loan amount in lesser then what you are sending");
        payable(allLoanRequests[_id].borrower).transfer(msg.value);
        allLoanRequests[_id].status = "approved";
        allLoans[allLoanRequests[_id].loanId].status = "given";
        allLoans[allLoanRequests[_id].loanId].amount = allLoans[allLoanRequests[_id].loanId].amount + allLoans[allLoanRequests[_id].loanId].amount*allLoans[allLoanRequests[_id].loanId].interestRate/100;
    }
    
    function declineLoanRequest(uint256 _id) external {
        allLoanRequests[_id].status = "declined";
    }

    function repayLoan(uint256 _id) external payable {
        if(block.timestamp <= allLoans[allLoanRequests[_id].loanId].dueTime){
            creditScore[msg.sender] -= 2;
        }
        else{
            creditScore[msg.sender] += 2;
        }
        uint256 repaymentAmount = msg.value;
        payable(allLoans[allLoanRequests[_id].loanId].lender).transfer(repaymentAmount);
        allLoanRequests[_id].status = "repaid";
        allLoans[allLoanRequests[_id].loanId].status = "repaid";
    }
}
