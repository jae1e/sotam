import pandas as pd

data = pd.DataFrame({
    'A': [2, 3, 4, 3, 4, 5],
    'B': ["a", "b", "c", "a", "b", "c"],
    'C': ["", "c", "d", "", "c", "d"],
})

ids = [3, 4]
selected_data = data[data['A'].isin(ids)]
print(selected_data)

grouped_data = selected_data.groupby('A')['B'].apply(list).to_dict()
print(grouped_data)

for id in grouped_data:
    print(grouped_data[id])

    # grouped_src = selected_src.groupby(id_title)[subject_column_title].apply(list).to_dict()
