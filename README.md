# Terraform による AKS デモ環境の展開

## 手順

### 最も簡単な方法

Cloud Shell を使って以下を実行します。

```
az account list
az account set --subscription <展開先のサブスクリプション>
curl -sL https://raw.githubusercontent.com/tsubasaxZZZ/aks-demo-environment/master/setup.sh | sh -s <リソース グループ名> <リージョン(AZのあるリージョン)>

例) curl -sL https://raw.githubusercontent.com/tsubasaxZZZ/aks-demo-environment/master/setup.sh | sh -s rg-aksdemo1 southeastasia | tee aksdemo_setup.log
```

成功すると最後に以下が出力されます。

※同じ結果が `aksdemo_setup.log` に出力されるため、あとで確認することもできます。

```
Apply complete! Resources: 53 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate
The behavior of this command has been altered by the following extension: aks-preview
Merged "aksdemowv6y5x" as current context in /home/tsubasa/.kube/config
deployment.apps/uploader created
service/uploader created
```

`kubectl` を実行すると展開されている Pod が確認できます。

```
kubectl  get po
```

[4. 確認](#validation) の手順で Application Gateway 経由でアプリケーションの展開が確認できます。


これ以降の手順はこの手順をステップバイステップで実行するものです。

### 1. Terraform 実行環境のセットアップ

以下のツールをインストールした Linux 環境を用意する。
もしくは CloudShell で実行する。

#### Azure CLI


- Install the Azure CLI(Cloud Shell の場合は実施不要)
    - https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
- Azure CLI のログイン(Cloud Shell の場合は実施不要)
    - az login
- サブスクリプションの選択(<font color="red">※展開先のサブスクリプションを間違えないこと</font>)
    - az account list
    - az account set --subscription <サブスクリプション>

#### terraform

※Cloud Shell の場合は実施不要

- Download Terraform
    - https://www.terraform.io/downloads.html

#### kubectl

※Cloud Shell の場合は実施不要

```
az aks install-cli
```

### 2. Terraform の実行

#### git clone

```
git clone https://github.com/tsubasaxZZZ/aks-demo-environment.git
cd aks-demo-environment
```

#### Terraform の実行

```
# 初期化
terraform init

# ランダム文字列のデプロイ
terraform apply -target random_string.uniqstr -var resource_group_name=<リソース グループ名> -var location=<リージョン(AZがあるリージョン)>

例) terraform apply -target random_string.uniqstr -var resource_group_name=rg-aksdemo2 -var location=southeastasia

# プラン
terraform plan -var resource_group_name=<リソース グループ名> -var location=<リージョン(AZがあるリージョン)> -out plan.tfplan

例) terraform plan -var resource_group_name=rg-aksdemo2 -var location=southeastasia -out plan.tfplan

# デプロイ
# ※1時間程度かかるため、Cloud Shell で実行している場合は定期的にキー操作を行う
terraform apply plan.tfplan
```

### 3. ワークロードのデプロイ

1. AKS の資格情報の取得
   - `az aks get-credentials -g <リソース グループ名> -n <AKSのクラスタ名>`

2. 生成された deployment.yaml で AKS へデプロイ。
   - `kubectl apply -f deployment.yaml`

### <a name="validation"></a>4. 確認

以下へアクセス。

`http://<Application Gateway の IP アドレス>/uploader/actuator/health`

以下の様なレスポンスが返ってくることを確認。

```
{"status":"UP","components":{"db":{"status":"UP","details":{"database":"Microsoft SQL Server","result":1,"validationQuery":"SELECT 1"}},"diskSpace":{"status":"UP","details":{"total":133018140672,"free":117697044480,"threshold":10485760}},"ping":{"status":"UP"}}}
```