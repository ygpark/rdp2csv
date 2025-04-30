import pandas as pd
import matplotlib.pyplot as plt
import argparse
import sys

def main():
    parser = argparse.ArgumentParser(description="시간대별 방문 수를 그래프로 출력하는 프로그램")
    parser.add_argument('-i', '--input', required=True, help='입력 CSV 파일 경로')
    args = parser.parse_args()

    try:
        # CSV 파일 읽기
        df = pd.read_csv(args.input)
    except Exception as e:
        print(f"[ERROR] 파일을 읽을 수 없습니다: {e}")
        sys.exit(1)

    # 'timestamp' 열이 있는지 확인
    if 'timestamp' not in df.columns:
        print("[ERROR] CSV 파일에 'timestamp' 열이 없습니다.")
        sys.exit(1)

    # timestamp 열을 datetime 타입으로 변환
    try:
        df['timestamp'] = pd.to_datetime(df['timestamp'])
    except Exception as e:
        print(f"[ERROR] 'timestamp' 열을 datetime으로 변환할 수 없습니다: {e}")
        sys.exit(1)

    # 'hour' 열 생성
    df['hour'] = df['timestamp'].dt.hour

    # 시간별 방문 수 집계
    visit_per_hour = df['hour'].value_counts().sort_index()

    # 그래프 그리기
    plt.figure(figsize=(10, 6))
    visit_per_hour.plot(kind='bar')
    plt.xlabel('Hour of Day')
    plt.ylabel('Number of Visits')
    plt.title('Visits per Hour')
    plt.xticks(rotation=0)
    plt.grid(axis='y')
    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    main()
