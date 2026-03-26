const imageExtension = 'svg';
const linkPrefix = '..'; // images will be hyperlinked with this prefix and subject ID (default: ../)
const autosaveKey = `table-viewer-ratings:${window.location.pathname}`;

document.addEventListener('DOMContentLoaded', () => {
    let originalData; // Variable to store the original data
    const table = document.getElementById('csv-table');
    const commandField = document.getElementById('command-field');
    const savedRatings = loadSavedRatings();


// Fetch data from the server
fetch('data.csv')
    .then(response => response.text())
    .then(data => {
        originalData = data; // Store the original data
        const rows = data.split('\n');
        let lowerBounds, upperBounds;

        // Loop through the rows to gather lower and upper bounds
        rows.forEach((row, index) => {
            const columns = row.split(',');
            const subjId = columns[0].trim();

            if (subjId === 'low') {
                lowerBounds = columns.slice(1).map(value => value.trim() === '' ? null : Number(value));
            } 
            if (subjId === 'high') {
                upperBounds = columns.slice(1).map(value => value.trim() === '' ? null : Number(value));
            }
        });

        // Loop through the rows again to apply the yellow background
        rows.forEach((row, index) => {
            const columns = row.split(',');
            const subjId = columns[0].trim();

            // Skip rows with identifiers "low" and "high" and empty ones
            if (subjId === '' || subjId === 'low' || subjId === 'high') {
                return;
            }

            const tr = document.createElement('tr');

            columns.forEach((column, colIndex) => {
                const td = document.createElement('td');
                td.textContent = column;
                
                const cellValue = parseFloat(column.trim());
                if (!isNaN(cellValue) && lowerBounds && upperBounds) {
                    if (lowerBounds[colIndex - 1] !== null && cellValue < lowerBounds[colIndex - 1]) {
                        td.style.backgroundColor = 'yellow'; // Cell value is lower than the lower bound
                    } else if (upperBounds[colIndex - 1] !== null && cellValue > upperBounds[colIndex - 1]) {
                        td.style.backgroundColor = 'yellow'; // Cell value is higher than the lower bound
                    }
                }

                tr.appendChild(td);


			    if (colIndex === columns.length - 1) {
			        const selectForm = document.createElement('select');
			        const options = ['good', 'rerun', 'bad']; // MODIFY if You need custom qc labels

			        options.forEach(option => {
			            const optionElement = document.createElement('option');
			            optionElement.value = option;
			            optionElement.textContent = option;
			            if (option === column) {
			                optionElement.selected = true; // Set the selected option based on cell value
			            }
			            selectForm.appendChild(optionElement);
			        });

			        if (savedRatings[subjId] && options.includes(savedRatings[subjId])) {
			            selectForm.value = savedRatings[subjId];
			            columns[colIndex] = savedRatings[subjId];
			        }

			        td.appendChild(selectForm);

					selectForm.addEventListener('change', function () {
					    const selectedValue = this.value;
					    if (selectedValue !== columns[colIndex]) {
					        tr.style.backgroundColor = selectedValue === 'bad' || selectedValue === 'rerun' ? 'red' : '';
					        columns[colIndex] = selectedValue;
					        saveRating(subjId, selectedValue);
					    }
					});
			    }
			});

            const imgTd = document.createElement('td');
            const container = document.createElement('div');
            
            container.classList.add('image-container');

            const link = document.createElement('a');
            link.href = `${linkPrefix}/${subjId}.html`;
            link.target = '_blank';
	
            const img = document.createElement('img');
            img.src = `imgs/${subjId}.${imageExtension}`; // Assuming images are named as subjId.jpg

            link.appendChild(img);
            container.appendChild(link);
            imgTd.appendChild(container);
            tr.appendChild(imgTd);

            const commandButton = document.createElement('button');
            commandButton.textContent = 'Run Command';
            commandButton.addEventListener('click', () => {
                const customCommand = commandField.value.replace(/\$subj/g, subjId);
                executeCommand(customCommand);
            });

            const commandTd = document.createElement('td');
            commandTd.appendChild(commandButton);
            tr.appendChild(commandTd);

            const currentRating = columns[columns.length - 1];
            tr.style.backgroundColor = currentRating === 'bad' || currentRating === 'rerun' ? 'red' : '';

            table.appendChild(tr);
        });
    })
    .catch(error => console.error('Error:', error));

    function loadSavedRatings() {
        try {
            const raw = window.localStorage.getItem(autosaveKey);
            return raw ? JSON.parse(raw) : {};
        } catch (error) {
            console.error('Could not load autosaved ratings:', error);
            return {};
        }
    }

    function saveRating(subjId, rating) {
        savedRatings[subjId] = rating;

        try {
            window.localStorage.setItem(autosaveKey, JSON.stringify(savedRatings));
        } catch (error) {
            console.error('Could not autosave rating:', error);
        }
    }

    function executeCommand(command) {
        var xhr = new XMLHttpRequest();
        xhr.open('GET', `cgi-bin/launch_cmd.sh?${command}`, true);
        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
        xhr.onload = function () {
            if (xhr.status >= 200 && xhr.status < 300) {
                console.log(xhr.responseText);
            } else {
                console.error('Request failed with status:', xhr.status);
            }
        };
        xhr.onerror = function () {
            console.error('Request failed');
        };
        xhr.send();
    }

	const saveButton = document.getElementById('save-button');
	saveButton.textContent = 'Save CSV';
	saveButton.addEventListener('click', () => {
	    const modifiedData = [...table.querySelectorAll('tr')].map(row => {
	        const cells = Array.from(row.querySelectorAll('td')).slice(0, -2); // Exclude the last two columns
	        const rowData = Array.from(cells).map(cell => {
	            const select = cell.querySelector('select');
	            if (select) {
	                return select.value;
	            } else if (cell.querySelector('input[type=checkbox]')) {
	                return cell.querySelector('input[type=checkbox]').checked ? '1' : '0';
	            }
	            return cell.textContent;
	        }).join(',');
	        return rowData;
	    }).join('\n');

	    // Create a Blob and download it as a CSV file
	    const blob = new Blob([modifiedData], { type: 'text/csv' });
	    const url = window.URL.createObjectURL(blob);
	    const a = document.createElement('a');
	    a.href = url;
	    a.download = 'modified_data.csv';
	    a.click();
	    window.URL.revokeObjectURL(url);
    });

});
