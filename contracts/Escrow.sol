//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external;
}

contract Escrow {
    address public nftAddress;
    address payable public seller;
    address public inspector;
    address public lender;
    


   modifier onlyBuyer(uint256 _nftId){
        require(msg.sender == buyer[_nftId], "Only buyer can call this method");
        _;
    }

    modifier onlySeller(){
        require(msg.sender == seller, "Only seller can call this method");
        _;
    }

    modifier onlyInspector(){
        require(msg.sender == inspector, "Only Inspector can call this method");
        _;
    }

    modifier onlyLender(){
        require(msg.sender == lender, "Only Lender can call this method");
        _;
    }

    mapping (uint256 => bool) public isListed;
    mapping (uint256 => uint256) public purchasePrice;
    mapping (uint256 => uint256) public escrowAmount;
    mapping (uint256 => address) public buyer;
    mapping (uint256 => bool) public inspectionPassed;
    mapping (uint256 => mapping (address => bool)) public approval;


    constructor(
        address _nftAddress,
        address payable _seller,
        address _inspector,
        address _lender) {
        nftAddress = _nftAddress;
        seller = _seller;
        inspector = _inspector;
        lender = _lender;
        
    }

    function list(
        uint256 _nftId,
        address _buyer,
        uint256 _purchasePrice,
        uint256 _escrowAmount
        ) public payable onlySeller{
        //Transfer NFT from seller to this contract
        IERC721(nftAddress).transferFrom(msg.sender, address(this), _nftId);

        isListed[_nftId] = true;
        purchasePrice[_nftId] = _purchasePrice;
        escrowAmount[_nftId] = _escrowAmount;
        buyer[_nftId] = _buyer;

    }

    //Put Under Contract (only buyer - payable escrow)
    function depositEarnest(uint256 _nftId) public payable onlyBuyer(_nftId){
        require(msg.value >= escrowAmount[_nftId]);
    }

    //Update Inspection Status (only inspector)
    function updateInspectionStatus(uint _nftId, bool _passed) public onlyInspector {
        inspectionPassed[_nftId] = _passed;
    }

    function approveSale(uint256 _nftId) public{
        approval[_nftId][msg.sender] = true;
    }


    function sendTransaction(uint256 _nftId) public payable onlyLender(){
        require(msg.value >= purchasePrice[_nftId]);
    }

    //finalize sale
    //-> require inspectoin status (add more items here, like appraisal)
    //-> Require sale to be aithorized
    //-> Require fund to be correct amount
    //-> Transfer NFT to buyer
    //-> Transfer funds to seller 

    function finalizeSale(uint256 _nftId) public {

        require(inspectionPassed[_nftId]);
        require(approval[_nftId][buyer[_nftId]]);
        require(approval[_nftId][seller]);
        require(approval[_nftId][lender]);
        require(address(this).balance >= purchasePrice[_nftId]);

        isListed[_nftId] = false;

        (bool success, ) = payable(seller).call{value:address(this).balance}("");
        require(success);

        IERC721(nftAddress).transferFrom(address(this), buyer[_nftId], _nftId);

    }

    //Cancel Sale (handle earnest deposit)
    //-> if inspection status is not approved, then refund, otherwise send to seller
    function cancelSale(uint256 _nftId) public{
        if(inspectionPassed[_nftId] == false) {
            payable(buyer[_nftId]).transfer(address(this).balance);

        } else {
            payable(seller).transfer(address(this).balance);
        }
    }
    
    receive() external payable{}

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }


}


