import matplotlib.pyplot as plt

cars_data_full = [
    {"Car": "Suzuki Baleno (NA)", "Rank": 1, "Pull_3000_6000": 9, "Turbo_Lag": 1, "Steering": 9, "Handling": 8, "Clutch": 3},
    {"Car": "Hyundai i20 N Line", "Rank": 2, "Pull_3000_6000": 7, "Turbo_Lag": 4, "Steering": 4, "Handling": 7, "Clutch": 9},
    {"Car": "Scorpio Classic (Diesel)", "Rank": 3, "Pull_3000_6000": 8, "Turbo_Lag": 8, "Steering": 3, "Handling": 2, "Clutch": 2},
    {"Car": "Fronx Turbo", "Rank": 4, "Pull_3000_6000": 6, "Turbo_Lag": 3, "Steering": 7, "Handling": 6, "Clutch": 7},
    {"Car": "Skoda Octavia 2.0 TDI (BS4)", "Rank": 5, "Pull_3000_6000": 10, "Turbo_Lag": 5, "Steering": 9, "Handling": 9, "Clutch": 6},
    {"Car": "Ertiga", "Rank": 6, "Pull_3000_6000": 2, "Turbo_Lag": 5, "Steering": 2, "Handling": 2, "Clutch": 4},
    {"Car": "Swift (2024 Model)", "Rank": 7, "Pull_3000_6000": 3, "Turbo_Lag": 2, "Steering": 3, "Handling": 3, "Clutch": 5}
]

# Extract data
car_labels = [car["Car"] for car in cars_data_full]
pull_scores = [car["Pull_3000_6000"] for car in cars_data_full]
turbo_lag_scores = [car["Turbo_Lag"] for car in cars_data_full]
steering_scores = [car["Steering"] for car in cars_data_full]
handling_scores = [car["Handling"] for car in cars_data_full]
clutch_scores = [car["Clutch"] for car in cars_data_full]

# Plot
x = range(len(car_labels))
bar_width = 0.15

plt.figure(figsize=(14, 8))
plt.bar([i - 2 * bar_width for i in x], pull_scores, width=bar_width, label='Pull (3k–6k RPM)', color='dodgerblue')
plt.bar([i - bar_width for i in x], turbo_lag_scores, width=bar_width, label='Turbo Lag (Inverse)', color='orange')
plt.bar(x, steering_scores, width=bar_width, label='Steering Feel', color='green')
plt.bar([i + bar_width for i in x], handling_scores, width=bar_width, label='Handling', color='red')
plt.bar([i + 2 * bar_width for i in x], clutch_scores, width=bar_width, label='Clutch Comfort', color='purple')

plt.xlabel("Car Models")
plt.ylabel("Score (1–10 scale)")
plt.title("Detailed Driving Dynamics Comparison")
plt.xticks(ticks=x, labels=car_labels, rotation=45, ha="right")
plt.legend()
plt.tight_layout()
plt.savefig("Detailed_Car_Comparison.png")
plt.show()
