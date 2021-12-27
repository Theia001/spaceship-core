pragma solidity ^0.6.0;

import '@openzeppelin/contracts/GSN/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Operator is Context, Ownable {
    mapping(address => bool) private _operator;
    address[] private _operatorList;

    event AddOperator(address operator);
    event RemoveOperator(address operator);

    constructor() internal {
        addOperator(_msgSender());

    }

    function operator() public view returns (address[] memory) {
        return _operatorList;
    }

    modifier onlyOperator() {
        require(
            _operator[_msgSender()],
            'operator: caller is not the operator'
        );
        _;
    }

    function isOperator() public view returns (bool) {
        return _operator[_msgSender()];
    }

    function addOperator(address _op) public onlyOwner {
        require(_op != address(0), "operator: not zero address");
        _operator[_op] = true;
        _operatorList.push(_op);
        emit AddOperator(_op);
    }

    function removeOperator(address _op) public onlyOwner {
        require(_op != address(0), "operator: not zero address");
        require(_operatorList.length > 0,"operator: not zero address");
        require(_operatorList.length > 0, "operator: no operator can remove");

        uint256 removeIndex;
        for (uint256 i = 0; i < _operatorList.length; i++) {
            if (_operatorList[i] == _op) {
                removeIndex = i;
                break;
            }
        }

        if (_operatorList[removeIndex] != _op) {
            return;
        }

        _operatorList[removeIndex] = _operatorList[_operatorList.length - 1];
        _operatorList.pop();
        _operator[_op] = false;
        emit RemoveOperator(_op);
    }


}
