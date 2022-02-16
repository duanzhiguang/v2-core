pragma solidity =0.5.16;

import './interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';

contract UniswapV2Factory is IUniswapV2Factory {
    address public feeTo;  //收税地址
    address public feeToSetter; //收税权限控制地址

    //配对映射，地址=》（地址=》地址）
    mapping(address => mapping(address => address)) public getPair;
    //所有配对数组
    address[] public allPairs;

    //事件：配对时被创建    indexed：带上索引
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    //构造方法：收税开关权限控制地址
    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }
    //查询配对数组长度方法
    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }
    //创建token合约对
    //returns pair:返回配对成功的地址
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        //默认a不等于b  token
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        
        //将 a b  token 进行排序，确保a小于b
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        
        //确认 token0 不等于0地址，也就是合约本身
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        
        //确认配对合约数组中不存在，token0(新建的配对合约地址)==>token1
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        
        //给keccak256变量赋值UniswapV2Pair合约的创建字节码  也就是创建token0 VS token1货币对的 新合约字节码信息
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        
        //将token0，token1经过abi打包后创建hash (solidity语言 ：keccak256哈希算法)
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        
        //1 新合约部署 开始：
        //内联汇编
        assembly {
            //通过create2方法部署合约，并且加盐，返回pair变量
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        //调用pair地址的合约中的 初始化方法 
        IUniswapV2Pair(pair).initialize(token0, token1);
        //2 部署初始化完成 结束：
        
        //映射token0=》token1到配对合约数组中
        getPair[token0][token1] = pair;
        //映射token1=》token0到配对合约数组中
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        //配对数组中加入新的配对合约地址
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
