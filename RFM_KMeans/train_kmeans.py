
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import joblib

from pathlib import Path
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import MiniBatchKMeans
from sklearn.metrics import silhouette_score

# =====================================
# 1. DOC DU LIEU
# =====================================

folder = Path(__file__).resolve().parent

df = pd.read_csv(folder / "customer_rfm.csv")

print("=== MO HINH RFM + K-MEANS ===")
print("So khach hang:", len(df))

features = ["Recency", "Frequency", "Monetary"]

# Kiem tra du lieu
assert len(df) == 1283707, "So khach hang chua khop"
assert not df[features].isnull().any().any()
assert not df["Customer_Key"].duplicated().any()
assert (df[features] >= 0).all().all()
assert (df["Frequency"] > 0).all()

# =====================================
# 2. BIEN DOI VA CHUAN HOA RFM
# =====================================

X = np.log1p(df[features].astype(float))

scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

print("Da chuan hoa du lieu RFM")

# =====================================
# 3. LAY MAU DE THU SO CUM
# =====================================

rng = np.random.default_rng(42)

sample_size = min(100000, len(df))

sample_idx = rng.choice(
    len(df),
    size=sample_size,
    replace=False
)

X_sample = X_scaled[sample_idx]

# =====================================
# 4. THU K TU 3 DEN 6
# =====================================

results = []
models = {}

for k in range(3, 7):

    print(f"\nDang thu K = {k}")

    model = MiniBatchKMeans(
        n_clusters=k,
        batch_size=4096,
        random_state=42,
        n_init=10,
        max_iter=150
    )

    model.fit(X_sample)

    labels = model.predict(X_sample)

    # Lay mau de tinh Silhouette
    score = silhouette_score(
        X_sample,
        labels,
        sample_size=3000,
        random_state=42
    )

    results.append({
        "K": k,
        "Silhouette": score,
        "Inertia": model.inertia_
    })

    models[k] = model

    print(f"Silhouette Score: {score:.4f}")

# =====================================
# 5. CHON SO CUM
# =====================================

result_df = pd.DataFrame(results)

print("\n=== BANG DANH GIA K ===")
print(result_df)

result_df.to_csv(
    folder / "k_evaluation.csv",
    index=False
)

best_k = int(
    result_df.loc[
        result_df["Silhouette"].idxmax(), "K"
    ]
)

print("\nK de xuat theo Silhouette:", best_k)

# =====================================
# 6. HUAN LUYEN MO HINH CUOI
# =====================================

best_model = MiniBatchKMeans(
    n_clusters=best_k,
    batch_size=4096,
    random_state=42,
    n_init=10,
    max_iter=200
)

# Huan luyen tren toan bo du lieu da chuan hoa
best_model.fit(X_scaled)

df["Cluster"] = best_model.predict(X_scaled)

# =====================================
# 7. THONG KE TUNG CUM
# =====================================

summary = df.groupby("Cluster").agg(
    Customers=("Customer_Key", "count"),
    Avg_Recency=("Recency", "mean"),
    Avg_Frequency=("Frequency", "mean"),
    Avg_Monetary=("Monetary", "mean"),
    Median_Recency=("Recency", "median"),
    Median_Frequency=("Frequency", "median"),
    Median_Monetary=("Monetary", "median"),
    Total_Revenue=("Monetary", "sum")
).reset_index()

summary["Customer_Share"] = (
    summary["Customers"] / len(df) * 100
)

summary["Revenue_Share"] = (
    summary["Total_Revenue"]
    / summary["Total_Revenue"].sum() * 100
)

print("\n=== KET QUA PHAN CUM ===")
print(summary.round(2).to_string(index=False))

# =====================================
# 8. LUU KET QUA
# =====================================

df.to_csv(
    folder / "customer_segments.csv",
    index=False
)

summary.to_csv(
    folder / "cluster_summary.csv",
    index=False
)

joblib.dump(
    {
        "model": best_model,
        "scaler": scaler,
        "features": features
    },
    folder / "rfm_kmeans_model.joblib"
)

# =====================================
# 9. VE BIEU DO CHON K
# =====================================

plt.figure(figsize=(8, 5))

plt.plot(
    result_df["K"],
    result_df["Silhouette"],
    marker="o"
)

plt.title("Silhouette Score theo so cum K")
plt.xlabel("So cum K")
plt.ylabel("Silhouette Score")
plt.xticks(result_df["K"])
plt.grid(alpha=0.3)
plt.tight_layout()

plt.savefig(
    folder / "silhouette_score.png",
    dpi=200
)

plt.close()

# =====================================
# 10. HOAN THANH
# =====================================

print("\n=== HOAN THANH MO HINH ===")
print("So cum duoc chon:", best_k)
print("Tong khach hang:", len(df))
print("Da luu file ket qua va bieu do")
