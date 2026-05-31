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
- [処理シーケンス](#-処理シーケンス)
- [ディレクトリ構成](#-ディレクトリ構成)
- [技術スタック](#-技術スタック)

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




## 🔄 処理シーケンス



<img width="842" height="835" alt="image" src="https://github.com/user-attachments/assets/6b25b7c5-03b3-4f39-a4c4-99bb26527acc" />




## 📁 ディレクトリ構成



<img width="625" height="372" alt="image" src="https://github.com/user-attachments/assets/ef690f9a-8e69-4062-a93f-a4091c0cefd8" />





## 🛠️ 技術スタック



<img width="829" height="470" alt="image" src="https://github.com/user-attachments/assets/d5d759a4-41f0-4efb-a954-21fcc9936d06" />




