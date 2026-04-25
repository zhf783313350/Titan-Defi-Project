package main
import ( 
	"fmt"     // 用于格式化输出
	"log"     // 用于记录错误日志
	"math/big" // 用于处理区块链中的大整数（如金额、价格）

	"github.com/ethereum/go-ethereum/common"    // 提供以太坊常用类型转换（如十六进制地址）
	"github.com/ethereum/go-ethereum/ethclient" // 以太坊客户端，用于连接区块链节点
	"titan-defi-project/bindings"               // 导入你刚才生成的 Go 绑定包
)

func main(){
	rpcURL := "http://127.0.0.1:8545"

	// 2. 连接到以太坊客户端
	// 使用 Dial 函数建立连接
	client, err := ethclient.Dial(rpcURL)
	if err != nil {
		log.Fatalf("连接区块链节点失败: %v", err)
	}
	fmt.Println("成功连接到区块链节点")
	contractAddress := common.HexToAddress("0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9")
	market, err := bindings.NewAuctionMarket(contractAddress, client)
	if err != nil {
		log.Fatalf("实例化合约绑定失败: %v", err)
	}
	price, err := market.GetLatestPrice(nil)
	if err != nil {
		log.Fatalf("从合约获取预言机价格失败: %v", err)
		return
	}
	fmt.Printf("预言机返回的原始价格数据: %s\n", price.String())
	fPrice := new(big.Float).SetInt(price)
	// 创建除数 10^8 (因为是 8 位精度)
	divisor := new(big.Float).SetFloat64(1e8)
	// 执行除法计算：实际美元价格 = 原始价格 / 10^8
	actualPrice := new(big.Float).Quo(fPrice, divisor)

	fmt.Printf("当前的 ETH 实时价格为: $%0.2f\n", actualPrice)
}
