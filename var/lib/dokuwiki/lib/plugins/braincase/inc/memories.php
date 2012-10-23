
<p style="margin-top: 10px;">These are the memories (backups) known to your Braincase.  You can revert to a prior memory by selecting it and clicking Remember.  Your current changes will not be lost.</p>

<table>
	<thead>
		<tr>
			<th>Date</th>
			<th>Source</th>
			<th></th>
		</tr>
	</thead>
	<tbody>
		<?php foreach ( $backups as $b ) : ?>
		<tr>
			<td><?php echo $b->date; ?></td>
			<td><?php echo $b->source; ?></td>
			<td style="text-align: center;"><button class="apply-backup">Remember</button></td>
		</tr>
		<?php endforeach; ?>
	</tbody>
</table>