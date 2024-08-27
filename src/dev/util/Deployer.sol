// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {vm} from "dev/util/vm.sol";
import {Json} from "dev/util/Json.sol";

library Deployer {
    function deployCode(string memory _what) internal returns (address addr) {
        addr = deployCode(_what, "", "");
    }

    function deployCode(string memory _what, bytes memory _args, string memory _salt) internal returns (address addr) {
        bytes memory bytecode = abi.encodePacked(vm.std_cheats.getCode(_what), _args);
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), _salt)
        }
    }

    function deployBytecode(bytes memory _initcode, bytes memory _args, string memory _salt)
        internal
        returns (address addr)
    {
        bytes memory bytecode = abi.encodePacked(_initcode, _args);
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), _salt)
        }
    }

    function ConditionalTokens() public returns (address) {
        //bytes memory initcode = Json.readData("artifacts/ConditionalTokens.json", ".bytecode.object");
        bytes memory initcode = "0x60806040526200001f6301ffc9a760e01b6001600160e01b036200004016565b6200003a636cdb3d1360e11b6001600160e01b036200004016565b620000c5565b6001600160e01b03198082161415620000a0576040805162461bcd60e51b815260206004820152601c60248201527f4552433136353a20696e76616c696420696e7465726661636520696400000000604482015290519081900360640190fd5b6001600160e01b0319166000908152602081905260409020805460ff19166001179055565b6139b380620000d56000396000f3fe608060405234801561001057600080fd5b50600436106101155760003560e01c8063856296f7116100a2578063d42dc0c211610071578063d42dc0c21461071a578063d96ee75414610737578063dd34de6714610769578063e985e9c514610786578063f242432a146107b457610115565b8063856296f7146105c45780639e7212ad146105ed578063a22cb46514610677578063c49298ac146106a557610115565b80632eb2c2d6116100e95780632eb2c2d61461024257806339dd7530146103695780634e1273f41461039557806372ce427514610508578063852c6ae21461059257610115565b8062fdd58e1461011a57806301b7037c1461015857806301ffc9a7146101e45780630504c8141461021f575b600080fd5b6101466004803603604081101561013057600080fd5b506001600160a01b038135169060200135610847565b60408051918252519081900360200190f35b6101e26004803603608081101561016e57600080fd5b6001600160a01b038235169160208101359160408201359190810190608081016060820135600160201b8111156101a457600080fd5b8201836020820111156101b657600080fd5b803590602001918460208302840111600160201b831117156101d757600080fd5b5090925090506108b9565b005b61020b600480360360208110156101fa57600080fd5b50356001600160e01b031916610c38565b604080519115158252519081900360200190f35b6101466004803603604081101561023557600080fd5b5080359060200135610c57565b6101e2600480360360a081101561025857600080fd5b6001600160a01b038235811692602081013590911691810190606081016040820135600160201b81111561028b57600080fd5b82018360208201111561029d57600080fd5b803590602001918460208302840111600160201b831117156102be57600080fd5b919390929091602081019035600160201b8111156102db57600080fd5b8201836020820111156102ed57600080fd5b803590602001918460208302840111600160201b8311171561030e57600080fd5b919390929091602081019035600160201b81111561032b57600080fd5b82018360208201111561033d57600080fd5b803590602001918460018302840111600160201b8311171561035e57600080fd5b509092509050610c85565b6101466004803603604081101561037f57600080fd5b506001600160a01b038135169060200135611012565b6104b8600480360360408110156103ab57600080fd5b810190602081018135600160201b8111156103c557600080fd5b8201836020820111156103d757600080fd5b803590602001918460208302840111600160201b831117156103f857600080fd5b9190808060200260200160405190810160405280939291908181526020018383602002808284376000920191909152509295949360208101935035915050600160201b81111561044757600080fd5b82018360208201111561045957600080fd5b803590602001918460208302840111600160201b8311171561047a57600080fd5b919080806020026020016040519081016040528093929190818152602001838360200280828437600092019190915250929550611025945050505050565b60408051602080825283518183015283519192839290830191858101910280838360005b838110156104f45781810151838201526020016104dc565b505050509050019250505060405180910390f35b6101e2600480360360a081101561051e57600080fd5b6001600160a01b038235169160208101359160408201359190810190608081016060820135600160201b81111561055457600080fd5b82018360208201111561056657600080fd5b803590602001918460208302840111600160201b8311171561058757600080fd5b91935091503561118c565b610146600480360360608110156105a857600080fd5b506001600160a01b038135169060208101359060400135611573565b610146600480360360608110156105da57600080fd5b5080359060208101359060400135611588565b6101e2600480360360a081101561060357600080fd5b6001600160a01b038235169160208101359160408201359190810190608081016060820135600160201b81111561063957600080fd5b82018360208201111561064b57600080fd5b803590602001918460208302840111600160201b8311171561066c57600080fd5b919350915035611595565b6101e26004803603604081101561068d57600080fd5b506001600160a01b038135169060200135151561198c565b6101e2600480360360408110156106bb57600080fd5b81359190810190604081016020820135600160201b8111156106dc57600080fd5b8201836020820111156106ee57600080fd5b803590602001918460208302840111600160201b8311171561070f57600080fd5b5090925090506119fa565b6101466004803603602081101561073057600080fd5b5035611ce4565b6101e26004803603606081101561074d57600080fd5b506001600160a01b038135169060208101359060400135611cf6565b6101466004803603602081101561077f57600080fd5b5035611e8e565b61020b6004803603604081101561079c57600080fd5b506001600160a01b0381358116916020013516611ea0565b6101e2600480360360a08110156107ca57600080fd5b6001600160a01b03823581169260208101359091169160408201359160608101359181019060a081016080820135600160201b81111561080957600080fd5b82018360208201111561081b57600080fd5b803590602001918460018302840111600160201b8311171561083c57600080fd5b509092509050611ece565b60006001600160a01b03831661088e5760405162461bcd60e51b815260040180806020018281038252602b8152602001806136fc602b913960400191505060405180910390fd5b5060008181526001602090815260408083206001600160a01b03861684529091529020545b92915050565b600083815260046020526040902054806109045760405162461bcd60e51b81526004018080602001828103825260258152602001806136d76025913960400191505060405180910390fd5b60008481526003602052604090205480610962576040805162461bcd60e51b815260206004820152601a60248201527918dbdb991a5d1a5bdb881b9bdd081c1c995c185c9959081e595d60321b604482015290519081900360640190fd5b60006000196001831b01815b85811015610aba57600087878381811061098457fe5b90506020020135905060008111801561099c57508281105b6109e5576040805162461bcd60e51b815260206004820152601560248201527419dbdd081a5b9d985b1a59081a5b99195e081cd95d605a1b604482015290519081900360640190fd5b60006109fb8c6109f68d8d866120aa565b6123d9565b90506000805b87811015610a58576001811b841615610a505760008c81526003602052604090208054610a4d919083908110610a3357fe5b90600052602060002001548361241d90919063ffffffff16565b91505b600101610a01565b506000610a653384610847565b90508015610aaa57610a9d610a908a610a84848663ffffffff61247716565b9063ffffffff6124d016565b889063ffffffff61241d16565b9650610aaa33848361253a565b50506001909201915061096e9050565b508115610ba55787610b81576040805163a9059cbb60e01b81523360048201526024810184905290516001600160a01b038b169163a9059cbb9160448083019260209291908290030181600087803b158015610b1557600080fd5b505af1158015610b29573d6000803e3d6000fd5b505050506040513d6020811015610b3f57600080fd5b5051610b7c5760405162461bcd60e51b815260040180806020018281038252602b815260200180613727602b913960400191505060405180910390fd5b610ba5565b610ba533610b8f8b8b6123d9565b84604051806020016040528060008152506125d5565b87896001600160a01b0316336001600160a01b03167f2682012a4a4f1973119f1c9b90745d1bd91fa2bab387344f044cb3586864d18d8a8a8a8860405180858152602001806020018381526020018281038252858582818152602001925060200280828437600083820152604051601f909101601f191690920182900397509095505050505050a4505050505050505050565b6001600160e01b03191660009081526020819052604090205460ff1690565b60036020528160005260406000208181548110610c7057fe5b90600052602060002001600091509150505481565b848314610cc35760405162461bcd60e51b815260040180806020018281038252602e815260200180613876602e913960400191505060405180910390fd5b6001600160a01b038716610d085760405162461bcd60e51b81526004018080602001828103825260288152602001806137526028913960400191505060405180910390fd5b6001600160a01b038816331480610d4757506001600160a01b038816600090815260026020908152604080832033845290915290205460ff1615156001145b610d825760405162461bcd60e51b81526004018080602001828103825260388152602001806138a46038913960400191505060405180910390fd5b60005b85811015610eb2576000878783818110610d9b57fe5b9050602002013590506000868684818110610db257fe5b905060200201359050610e04816001600085815260200190815260200160002060008e6001600160a01b03166001600160a01b03168152602001908152602001600020546126c390919063ffffffff16565b6001600084815260200190815260200160002060008d6001600160a01b03166001600160a01b0316815260200190815260200160002081905550610e876001600084815260200190815260200160002060008c6001600160a01b03166001600160a01b03168152602001908152602001600020548261241d90919063ffffffff16565b60009283526001602081815260408086206001600160a01b038f168752909152909320555001610d85565b50866001600160a01b0316886001600160a01b0316336001600160a01b03167f4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb898989896040518080602001806020018381038352878782818152602001925060200280828437600083820152601f01601f19169091018481038352858152602090810191508690860280828437600083820152604051601f909101601f19169092018290039850909650505050505050a461100833898989898080602002602001604051908101604052809392919081815260200183836020028082843760009201919091525050604080516020808d0282810182019093528c82529093508c92508b91829185019084908082843760009201919091525050604080516020601f8c018190048102820181019092528a815292508a915089908190840183828082843760009201919091525061272092505050565b5050505050505050565b600061101e83836123d9565b9392505050565b606081518351146110675760405162461bcd60e51b815260040180806020018281038252602e815260200180613848602e913960400191505060405180910390fd5b60608351604051908082528060200260200182016040528015611094578160200160208202803883390190505b50905060005b84518110156111845760006001600160a01b03168582815181106110ba57fe5b60200260200101516001600160a01b031614156111085760405162461bcd60e51b81526004018080602001828103825260348152602001806137f36034913960400191505060405180910390fd5b6001600085838151811061111857fe5b60200260200101518152602001908152602001600020600086838151811061113c57fe5b60200260200101516001600160a01b03166001600160a01b031681526020019081526020016000205482828151811061117157fe5b602090810291909101015260010161109a565b509392505050565b600182116111e1576040805162461bcd60e51b815260206004820181905260248201527f676f7420656d707479206f722073696e676c65746f6e20706172746974696f6e604482015290519081900360640190fd5b6000848152600360205260409020548061123f576040805162461bcd60e51b815260206004820152601a60248201527918dbdb991a5d1a5bdb881b9bdd081c1c995c185c9959081e595d60321b604482015290519081900360640190fd5b6040805184815260208086028201019091526000196001831b01908190606090868015611276578160200160208202803883390190505b5090506060878790506040519080825280602002602001820160405280156112a8578160200160208202803883390190505b50905060005b878110156113c05760008989838181106112c457fe5b9050602002013590506000811180156112dc57508581105b611325576040805162461bcd60e51b815260206004820152601560248201527419dbdd081a5b9d985b1a59081a5b99195e081cd95d605a1b604482015290519081900360640190fd5b8085821614611374576040805162461bcd60e51b81526020600482015260166024820152751c185c9d1a5d1a5bdb881b9bdd08191a5cda9bda5b9d60521b604482015290519081900360640190fd5b938418936113878d6109f68e8e856120aa565b84838151811061139357fe5b602002602001018181525050878383815181106113ac57fe5b6020908102919091010152506001016112ae565b50826114a5578961148c57604080516323b872dd60e01b81523360048201523060248201526044810188905290516001600160a01b038d16916323b872dd9160648083019260209291908290030181600087803b15801561142057600080fd5b505af1158015611434573d6000803e3d6000fd5b505050506040513d602081101561144a57600080fd5b50516114875760405162461bcd60e51b81526004018080602001828103825260238152602001806137d06023913960400191505060405180910390fd5b6114a0565b6114a03361149a8d8d6123d9565b8861253a565b6114ba565b6114ba3361149a8d6109f68e8e898b186120aa565b6114d5338383604051806020016040528060008152506128fd565b888a336001600160a01b03167f2e6bb91f8cbcda0c93623c54d0403a43514fabc40084ec96b6d5379a747862988e8c8c8c60405180856001600160a01b03166001600160a01b03168152602001806020018381526020018281038252858582818152602001925060200280828437600083820152604051601f909101601f191690920182900397509095505050505050a45050505050505050505050565b6000611580848484612b30565b949350505050565b60006115808484846120aa565b600182116115ea576040805162461bcd60e51b815260206004820181905260248201527f676f7420656d707479206f722073696e676c65746f6e20706172746974696f6e604482015290519081900360640190fd5b60008481526003602052604090205480611648576040805162461bcd60e51b815260206004820152601a60248201527918dbdb991a5d1a5bdb881b9bdd081c1c995c185c9959081e595d60321b604482015290519081900360640190fd5b6040805184815260208086028201019091526000196001831b0190819060609086801561167f578160200160208202803883390190505b5090506060878790506040519080825280602002602001820160405280156116b1578160200160208202803883390190505b50905060005b878110156117c95760008989838181106116cd57fe5b9050602002013590506000811180156116e557508581105b61172e576040805162461bcd60e51b815260206004820152601560248201527419dbdd081a5b9d985b1a59081a5b99195e081cd95d605a1b604482015290519081900360640190fd5b808582161461177d576040805162461bcd60e51b81526020600482015260166024820152751c185c9d1a5d1a5bdb881b9bdd08191a5cda9bda5b9d60521b604482015290519081900360640190fd5b938418936117908d6109f68e8e856120aa565b84838151811061179c57fe5b602002602001018181525050878383815181106117b557fe5b6020908102919091010152506001016116b7565b506117d5338383612b7d565b826118d957896118b0576040805163a9059cbb60e01b81523360048201526024810188905290516001600160a01b038d169163a9059cbb9160448083019260209291908290030181600087803b15801561182e57600080fd5b505af1158015611842573d6000803e3d6000fd5b505050506040513d602081101561185857600080fd5b50516118ab576040805162461bcd60e51b815260206004820181905260248201527f636f756c64206e6f742073656e6420636f6c6c61746572616c20746f6b656e73604482015290519081900360640190fd5b6118d4565b6118d4336118be8d8d6123d9565b88604051806020016040528060008152506125d5565b6118ee565b6118ee336118be8d6109f68e8e898b186120aa565b888a336001600160a01b03167f6f13ca62553fcc2bcd2372180a43949c1e4cebba603901ede2f4e14f36b282ca8e8c8c8c60405180856001600160a01b03166001600160a01b03168152602001806020018381526020018281038252858582818152602001925060200280828437600083820152604051601f909101601f191690920182900397509095505050505050a45050505050505050505050565b3360008181526002602090815260408083206001600160a01b03871680855290835292819020805460ff1916861515908117909155815190815290519293927f17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31929181900390910190a35050565b8060018111611a3a5760405162461bcd60e51b815260040180806020018281038252602a8152602001806138dc602a913960400191505060405180910390fd5b6000611a47338684612b30565b6000818152600360205260409020549091508214611aac576040805162461bcd60e51b815260206004820152601f60248201527f636f6e646974696f6e206e6f74207072657061726564206f7220666f756e6400604482015290519081900360640190fd5b60008181526004602052604090205415611b0d576040805162461bcd60e51b815260206004820152601e60248201527f7061796f75742064656e6f6d696e61746f7220616c7265616479207365740000604482015290519081900360640190fd5b6000805b83811015611bf2576000868683818110611b2757fe5b905060200201359050611b43818461241d90919063ffffffff16565b600085815260036020526040902080549194509083908110611b6157fe5b9060005260206000200154600014611bc0576040805162461bcd60e51b815260206004820152601c60248201527f7061796f7574206e756d657261746f7220616c72656164792073657400000000604482015290519081900360640190fd5b6000848152600360205260409020805482919084908110611bdd57fe5b60009182526020909120015550600101611b11565b5060008111611c3f576040805162461bcd60e51b81526020600482015260146024820152737061796f757420697320616c6c207a65726f657360601b604482015290519081900360640190fd5b60008281526004602090815260408083208490556003825291829020825186815291820183815281549383018490528993339387937fb44d84d3289691f71497564b85d4233648d9dbae8cbdbb4329f301c3a0185894938a93919291606083019084908015611ccd57602002820191906000526020600020905b815481526020019060010190808311611cb9575b5050935050505060405180910390a4505050505050565b60009081526003602052604090205490565b610100811115611d46576040805162461bcd60e51b8152602060048201526016602482015275746f6f206d616e79206f7574636f6d6520736c6f747360501b604482015290519081900360640190fd5b60018111611d855760405162461bcd60e51b815260040180806020018281038252602a8152602001806138dc602a913960400191505060405180910390fd5b6000611d92848484612b30565b60008181526003602052604090205490915015611df6576040805162461bcd60e51b815260206004820152601a60248201527f636f6e646974696f6e20616c7265616479207072657061726564000000000000604482015290519081900360640190fd5b81604051908082528060200260200182016040528015611e20578160200160208202803883390190505b5060008281526003602090815260409091208251611e44939192919091019061366e565b5082846001600160a01b0316827fab3760c3bd2bb38b5bcf54dc79802ed67338b4cf29f3054ded67ed24661e4177856040518082815260200191505060405180910390a450505050565b60046020526000908152604090205481565b6001600160a01b03918216600090815260026020908152604080832093909416825291909152205460ff1690565b6001600160a01b038516611f135760405162461bcd60e51b81526004018080602001828103825260288152602001806137526028913960400191505060405180910390fd5b6001600160a01b038616331480611f5257506001600160a01b038616600090815260026020908152604080832033845290915290205460ff1615156001145b611f8d5760405162461bcd60e51b81526004018080602001828103825260388152602001806138a46038913960400191505060405180910390fd5b60008481526001602090815260408083206001600160a01b038a168452909152902054611fc0908463ffffffff6126c316565b60008581526001602090815260408083206001600160a01b038b81168552925280832093909355871681522054611ff890849061241d565b60008581526001602090815260408083206001600160a01b03808b16808652918452938290209490945580518881529182018790528051928a169233927fc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f6292908290030190a46120a2338787878787878080601f016020809104026020016040519081016040528093929190818152602001838380828437600092019190915250612d6192505050565b505050505050565b6040805160208082018590528183018490528251808303840181526060909201909252805191012060009060ff81901c151582805b60008051602061377a83398151915260018508935060008051602061377a833981519152600360008051602061377a83398151915280878809870908905061212681612ec3565b91508060008051602061377a83398151915283840914156120df5782801561214f575060028206155b806121665750821580156121665750600282066001145b1561217f578160008051602061377a8339815191520391505b8780156123b65760fe81901c151593506001600160fe1b031660008051602061377a833981519152600360008051602061377a83398151915280848509840908915060006121cc83612ec3565b90508480156121dc575060028106155b806121f35750841580156121f35750600281066001145b156122095760008051602061377a833981519152035b8260008051602061377a8339815191528283091461226e576040805162461bcd60e51b815260206004820152601c60248201527f696e76616c696420706172656e7420636f6c6c656374696f6e20494400000000604482015290519081900360640190fd5b6000606060066001600160a01b031688878686604051602001808581526020018481526020018381526020018281526020019450505050506040516020818303038152906040526040518082805190602001908083835b602083106122e45780518252601f1990920191602091820191016122c5565b6001836020036101000a038019825116818451168082178552505050505050905001915050600060405180830381855afa9150503d8060008114612344576040519150601f19603f3d011682016040523d82523d6000602084013e612349565b606091505b50915091508161238f576040805162461bcd60e51b815260206004820152600c60248201526b1958d859190819985a5b195960a21b604482015290519081900360640190fd5b8080602001905160408110156123a457600080fd5b50805160209091015190985095505050505b60028306600114156123cc57600160fe1b851894505b5092979650505050505050565b6040805160609390931b6bffffffffffffffffffffffff19166020808501919091526034808501939093528151808503909301835260549093019052805191012090565b60008282018381101561101e576040805162461bcd60e51b815260206004820152601b60248201527f536166654d6174683a206164646974696f6e206f766572666c6f770000000000604482015290519081900360640190fd5b600082612486575060006108b3565b8282028284828161249357fe5b041461101e5760405162461bcd60e51b81526004018080602001828103825260218152602001806138276021913960400191505060405180910390fd5b6000808211612526576040805162461bcd60e51b815260206004820152601a60248201527f536166654d6174683a206469766973696f6e206279207a65726f000000000000604482015290519081900360640190fd5b600082848161253157fe5b04949350505050565b60008281526001602090815260408083206001600160a01b038716845290915290205461256d908263ffffffff6126c316565b60008381526001602090815260408083206001600160a01b038816808552908352818420949094558051868152918201859052805192939233927fc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f6292908290030190a4505050565b6001600160a01b03841661261a5760405162461bcd60e51b815260040180806020018281038252602181526020018061392d6021913960400191505060405180910390fd5b60008381526001602090815260408083206001600160a01b038816845290915290205461264e90839063ffffffff61241d16565b60008481526001602090815260408083206001600160a01b038916808552908352818420949094558051878152918201869052805133927fc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f6292908290030190a46126bd33600086868686612d61565b50505050565b60008282111561271a576040805162461bcd60e51b815260206004820152601e60248201527f536166654d6174683a207375627472616374696f6e206f766572666c6f770000604482015290519081900360640190fd5b50900390565b612732846001600160a01b0316613668565b156120a25760405163bc197c8160e01b8082526001600160a01b0388811660048401908152888216602485015260a060448501908152875160a4860152875193949289169363bc197c81938c938c938b938b938b9392916064820191608481019160c4909101906020808a01910280838360005b838110156127be5781810151838201526020016127a6565b50505050905001848103835286818151815260200191508051906020019060200280838360005b838110156127fd5781810151838201526020016127e5565b50505050905001848103825285818151815260200191508051906020019080838360005b83811015612839578181015183820152602001612821565b50505050905090810190601f1680156128665780820380516001836020036101000a031916815260200191505b5098505050505050505050602060405180830381600087803b15801561288b57600080fd5b505af115801561289f573d6000803e3d6000fd5b505050506040513d60208110156128b557600080fd5b50516001600160e01b031916146120a25760405162461bcd60e51b815260040180806020018281038252603681526020018061379a6036913960400191505060405180910390fd5b6001600160a01b0384166129425760405162461bcd60e51b81526004018080602001828103825260278152602001806139066027913960400191505060405180910390fd5b81518351146129825760405162461bcd60e51b815260040180806020018281038252602e815260200180613876602e913960400191505060405180910390fd5b60005b8351811015612a46576129fd600160008684815181106129a157fe5b602002602001015181526020019081526020016000206000876001600160a01b03166001600160a01b03168152602001908152602001600020548483815181106129e757fe5b602002602001015161241d90919063ffffffff16565b60016000868481518110612a0d57fe5b602090810291909101810151825281810192909252604090810160009081206001600160a01b038a168252909252902055600101612985565b50836001600160a01b031660006001600160a01b0316336001600160a01b03167f4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb8686604051808060200180602001838103835285818151815260200191508051906020019060200280838360005b83811015612acd578181015183820152602001612ab5565b50505050905001838103825284818151815260200191508051906020019060200280838360005b83811015612b0c578181015183820152602001612af4565b5050505090500194505050505060405180910390a46126bd33600086868686612720565b6040805160609490941b6bffffffffffffffffffffffff19166020808601919091526034850193909352605480850192909252805180850390920182526074909301909252815191012090565b8051825114612bbd5760405162461bcd60e51b815260040180806020018281038252602e815260200180613876602e913960400191505060405180910390fd5b60005b8251811015612c8157612c38828281518110612bd857fe5b602002602001015160016000868581518110612bf057fe5b602002602001015181526020019081526020016000206000876001600160a01b03166001600160a01b03168152602001908152602001600020546126c390919063ffffffff16565b60016000858481518110612c4857fe5b602090810291909101810151825281810192909252604090810160009081206001600160a01b0389168252909252902055600101612bc0565b5060006001600160a01b0316836001600160a01b0316336001600160a01b03167f4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb8585604051808060200180602001838103835285818151815260200191508051906020019060200280838360005b83811015612d08578181015183820152602001612cf0565b50505050905001838103825284818151815260200191508051906020019060200280838360005b83811015612d47578181015183820152602001612d2f565b5050505090500194505050505060405180910390a4505050565b612d73846001600160a01b0316613668565b156120a25760405163f23a6e6160e01b8082526001600160a01b03888116600484019081528882166024850152604484018790526064840186905260a060848501908152855160a4860152855193949289169363f23a6e61938c938c938b938b938b93929160c490910190602085019080838360005b83811015612e01578181015183820152602001612de9565b50505050905090810190601f168015612e2e5780820380516001836020036101000a031916815260200191505b509650505050505050602060405180830381600087803b158015612e5157600080fd5b505af1158015612e65573d6000803e3d6000fd5b505050506040513d6020811015612e7b57600080fd5b50516001600160e01b031916146120a25760405162461bcd60e51b815260040180806020018281038252603181526020018061394e6031913960400191505060405180910390fd5b600060008051602061377a833981519152808380099150808283098181820990508181840992508183850993508184840992508183840990508181820982818309905082818209905082818209905082818309915082828609945082858609915082828309915082828509935082848509915082828309915082828309915082828509915082828609945082858609915082828309915082828309915082828609915082828509935082848609945082858609915082828309915082828509935082848509915082828309905082818209905082818209905082818309915082828609945082858509935082848509915082828309915082828309915082828609945082858609915082828309915082828609915082828309915082828309915082828609915082828509935082848509915082828309905082818209905082818309905082818509905082818209905082818209905082818209905082818209905082818309915082828609945082858609915082828609915082828509935082848509915082828509915082828309915082828309905082818309905082818209838182099050838182099050838182099050838182099050838183099150508281830991508282860994508285850993508284850991508282860994508285850993508284860994508285850993508284860994508285860991508282860991508282830991508282850993508284850991508282830991508282860994508285850993508284850991508282850991508282860994508285850993508284860994508285850993508284850991508282830991508282850991508282860994508285860991508282860991508282850993508284860994508285850993508284860994508285850993508284850991508282850991508282830991508282860994508285850993508284850991508282850991508282830991508282860994508285860991508282830990508281820990508281830990508281860990508281820990508281820990508281820990508281820990508281830991508282850993508284860994508285850993508284860994508285860991508282860991508282830991508282830991508282830991508282860991508282850993508284850991508282850991508282830991508282860994508285860991508282860991508282850993508284860994508285860991508282830991508282850993508284860994508285860991508282850993508284860994508285850993508284850991508282850991508282860994508285850993508284850991508282850991508282830991508282830991508282860994508285860991508282830991508282830991508282860991508282850993508284860994508285860991508282860990508281820990508281820990508281830991508282850993508284850991508282860994508285850993508284860994508285850993508284860994508285850993508284850991508282850990508281850991508282830991508282830991508282820991505081818509935081848409925081838509935081848409925081838509935081848509905081818509905081818409925050808284099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808384099250808383099392505050565b3b151590565b8280548282559060005260206000209081019282156136a9579160200282015b828111156136a957825182559160200191906001019061368e565b506136b59291506136b9565b5090565b6136d391905b808211156136b557600081556001016136bf565b9056fe726573756c7420666f7220636f6e646974696f6e206e6f7420726563656976656420796574455243313135353a2062616c616e636520717565727920666f7220746865207a65726f2061646472657373636f756c64206e6f74207472616e73666572207061796f757420746f206d6573736167652073656e646572455243313135353a207461726765742061646472657373206d757374206265206e6f6e2d7a65726f30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47455243313135353a20676f7420756e6b6e6f776e2076616c75652066726f6d206f6e4552433131353542617463685265636569766564636f756c64206e6f74207265636569766520636f6c6c61746572616c20746f6b656e73455243313135353a20736f6d65206164647265737320696e2062617463682062616c616e6365207175657279206973207a65726f536166654d6174683a206d756c7469706c69636174696f6e206f766572666c6f77455243313135353a206f776e65727320616e6420494473206d75737420686176652073616d65206c656e67746873455243313135353a2049447320616e642076616c756573206d75737420686176652073616d65206c656e67746873455243313135353a206e656564206f70657261746f7220617070726f76616c20666f7220337264207061727479207472616e73666572732e74686572652073686f756c64206265206d6f7265207468616e206f6e65206f7574636f6d6520736c6f74455243313135353a206261746368206d696e7420746f20746865207a65726f2061646472657373455243313135353a206d696e7420746f20746865207a65726f2061646472657373455243313135353a20676f7420756e6b6e6f776e2076616c75652066726f6d206f6e455243313135355265636569766564a265627a7a72315820d49dab2b950cf3b366255f06404d652fc0f2fa23c05a368e53552f98cdd0b95464736f6c63430005100032";
        return deployBytecode(initcode, "", "");
    }
}
