# 🛡️ JPX Sentinel ECS
### JPX 上場廃止銘柄 自動監視システム

![Python](https://img.shields.io/badge/Python-3.13-3776AB?style=flat-square&logo=python&logoColor=white)
![Java](https://img.shields.io/badge/Java-Spring_Boot-6DB33F?style=flat-square&logo=springboot&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-ECS_Fargate-FF9900?style=flat-square&logo=amazonaws&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=flat-square&logo=mysql&logoColor=white)
![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?style=flat-square&logo=terraform&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=flat-square&logo=docker&logoColor=white)
![Slack](https://img.shields.io/badge/Notify-Slack_Webhook-4A154B?style=flat-square&logo=slack&logoColor=white)
![Version](https://img.shields.io/badge/version-v1.0.0-success?style=flat-square)

---

> 東京証券取引所（JPX）公式サイトの「上場廃止等の公表」ページを定期自動監視し、  
> **新規公示を即時 Slack 通知 + MySQL 蓄積**する AWS ECS バッチシステムです。

---

## 📌 目次 / Table of Contents

- [背景・目的](#-背景目的)
- [システム構成](#-システム構成)
- [技術スタック](#-技術スタック)
- [ディレクトリ構成](#-ディレクトリ構成)
- [実行モード](#-実行モード)
- [セットアップ（ローカル開発）](#-セットアップローカル開発)
- [環境変数](#-環境変数)
- [APIエンドポイント](#-apiエンドポイント)
- [DBテーブル定義](#-dbテーブル定義)
- [処理シーケンス](#-処理シーケンス)
- [テスト観点](#-テスト観点)

---

## 🎯 背景・目的

JPX 上場廃止情報の**手動確認作業を完全自動化**するために開発したシステムです。

| 課題 | 解決策 |
|------|--------|
| 手動確認による工数・見落としリスク | EventBridge による定期自動実行 |
| 重複通知・重複登録の発生 | MySQL UNIQUE 制約 + `INSERT IGNORE` |
| 公示データの一元管理が困難 | RDS への永続化 + Spring Boot Excel 出力 |

---

## 🏗️ システム構成
<img width="1372" height="784" alt="Gemini_Generated_Image_sqnbbysqnbbysqnb" src="https://github.com/user-attachments/assets/ece8a447-bc6d-42f2-9ac7-caa41e06ff08" />



<img width="804" height="324" alt="image" src="https://github.com/user-attachments/assets/7cdaf97f-4322-4bc1-a2f0-978a566759b4" />





<img width="864" height="524" alt="image" src="https://github.com/user-attachments/assets/d1090f72-2770-4809-b95b-7ef5658d7471" />





📁 ディレクトリ構成
<img width="625" height="372" alt="image" src="https://github.com/user-attachments/assets/ef690f9a-8e69-4062-a93f-a4091c0cefd8" />




⚙️ 実行モード
APP_MODE 環境変数によって動作を切り替えます。

bash

# BATCH モード（本番 / デフォルト）
# ECS タスク起動と同時にスクレイピングを実行し、完了後に自動終了
APP_MODE=BATCH
# DEV モード（開発）
# Flask サーバーを常駐させ、API エンドポイントで手動実行可能
APP_MODE=DEV

モード	動作	用途
BATCH	起動 → スクレイピング → 自動終了	ECS 本番運用
DEV	Flask 常駐 + API 経由で任意実行	ローカル開発・テスト

🚀 セットアップ（ローカル開発）
前提条件
Docker / Docker Compose インストール済み
Slack Incoming Webhook URL 取得済み
手順
bash

# 1. リポジトリをクローン
git clone [github.com](https://github.com/shangchoco/jpx-sentinel-ecs.git)
cd jpx-sentinel-ecs
# 2. 環境変数ファイルを作成
cp .env.example .env
# .env を編集して各値を設定（下記「環境変数」参照）
# 3. コンテナ起動
docker compose up -d
# 4. DEV モードでスクレイピングを手動実行
curl [localhost](http://localhost:5000/python/scrape)

🔐 環境変数
.env ファイルまたは ECS タスク定義で設定してください。
認証情報はソースコードに直接書かないでください。



変数名	説明	例
APP_MODE	実行モード	BATCH / DEV
MYSQL_HOST	MySQL ホスト	db / RDS エンドポイント
MYSQL_PORT	MySQL ポート	3306
MYSQL_DATABASE	DB 名	jpx_database
MYSQL_USER	DB ユーザー	jpxuser
MYSQL_PASSWORD	DB パスワード	**強固な文字列を設定**
SLACK_WEBHOOK_URL	Slack Webhook URL	[hooks.slack.com](https://hooks.slack.com/)
PYTHONUNBUFFERED	ログリアルタイム出力	1

🔌 API エンドポイント
DEV モード起動時のみ有効です。

メソッド	エンドポイント	説明	レスポンス
GET	/	ヘルスチェック	200 OK
GET	/python/scrape	スクレイピング手動実行	JSON
/python/scrape レスポンス例
json


{
  "status": "success",
  "message": "本日新規公示 2件 登録。",
  "total_scraped": 5,
  "new_inserted": 2
}

🗄️ DB テーブル定義
テーブル名: delistings　DB: jpx_database　エンジン: MySQL 8.0 InnoDB
カラム名	型	PK	NOT NULL	説明
id	INT	✅	✅	AUTO_INCREMENT サロゲートキー
stock_code	VARCHAR(20)	—	✅	銘柄コード（UNIQUE・半角変換済）
stock_name	VARCHAR(100)	—	✅	銘柄名（株式会社除去・正規化済）
delisting_date	VARCHAR(50)	—	—	上場廃止予定日（例: 2026年6月30日）
cleanup_start_date	VARCHAR(50)	—	—	整理売買開始日
cleanup_end_date	VARCHAR(50)	—	—	整理売買終了日
news_url	VARCHAR(512)	—	—	JPX 詳細ページ URL
created_at	DATETIME	—	✅	レコード作成日時（DEFAULT CURRENT_TIMESTAMP）

🔄 処理シーケンス

<img width="965" height="750" alt="diagram" src="https://github.com/user-attachments/assets/06c63539-010f-479d-bf65-6ad91dcb2502" />

